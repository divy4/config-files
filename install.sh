#!/usr/bin/env bash
set -euo pipefail

REPO_PATH="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

# Helper functions are in another file because there's a lot of them.
# shellcheck disable=SC1091
source "$REPO_PATH/helpers.sh"

function main {
  local tool
  # Sleep for 0 seconds so the terminal size is detected correctly... magic...
  sleep 0
  # Ensure we're not running as root
  fail_if_running_as_root
  # Always execute cleanup
  trap cleanup EXIT
  # Create a temporary directory
  echo 'Creating temporary directory...'
  TEMP_DIR="$(mktemp --directory)"
  # Ensure we're at the repo root
  cd "$REPO_PATH" || exit

  # Execute each tool
  for tool in $(get_configure_functions "$@"); do
    print_header "${tool^}"
    "configure_$tool"
  done
}

function cleanup {
  local exit_code=$?
  print_header 'Cleanup'
  echo 'Deleting temporary directory...'
  rm -rf "$TEMP_DIR"
  if [[ "$exit_code" -eq 0 ]]; then
    print_header 'Done!'
  else
    print_header 'Failed'
  fi
}

# Tools

function configure_code {
  local command config_dir extensions_file
  case "$(get_machine_type)" in
    infrastructure)
      echo 'Infrastructure machine, skipping.'
      return 0;;
    personal)
      command='codium'
      config_dir="$HOME/.config/VSCodium"
      extensions_file='code/extensions';;
    work)
      command='code'
      config_dir='/mnt/c/Users/DIvy/AppData/Roaming/Code/'
      extensions_file='code/extensions_work';;
  esac

  install_with_prompt --mode=644 -D code/settings.json "$config_dir/User/settings.json"

  mapfile -t missing_extensions < <(
    comm -23 <(sort "$extensions_file") \
         <("$command" --list-extensions | sort)
  )
  if [[ "${#missing_extensions[@]}" -eq 0 ]]; then
    printf 'Code extensions are up to date.\n'
  else
    echo "Missing Code extensions:"
    printf '%s\n' "${missing_extensions[@]}"
    if confirm 'Install missing Code extensions?'; then
      printf '%s\n' "${missing_extensions[@]}" \
      | xargs --max-lines=1 "$command" --install-extension
    else
      echo "Skipping."
    fi
  fi
}

function configure_fluxbox {
  local regex apps
  if [[ "$(get_machine_type)" =~ ^(work|infrastructure)$ ]]; then
    echo 'Work or infrastructure machine, skipping.'
    return 0
  elif [[ ! -d "$HOME/.fluxbox" ]]; then
    echo 'No fluxbox directory, skipping.'
    return 0
  fi

  # Render fluxbox menu with machine-specific tools installed

  # Figure out what apps exist on the system.
  regex="^(\s*)#\s*autoexec\s*(.*\{(.*?)\})\s*$"
  mapfile -t apps < <(
    grep '# autoexec' fluxbox/menu \
    | sed --regexp-extended "s/$regex/\3/g" \
    | grep_if_command
  )

  # Uncomment 'autoexec' lines of commands that exist, then remove the rest.
  regex="^(\s*)#\s*autoexec\s*(.*\{($(join '|' "${apps[@]}"))\})\s*$"
  sed --regexp-extended "s/$regex/\1\2/g" fluxbox/menu \
  | grep --invert-match '#\s*autoexec' \
  > "$TEMP_DIR/menu"

  # Copy files
  install_with_prompt --mode=644 fluxbox/styles/black ~/.fluxbox/styles/black
  install_with_prompt --mode=644 fluxbox/apps ~/.fluxbox/apps
  install_with_prompt --mode=644 fluxbox/groups ~/.fluxbox/groups
  install_with_prompt --mode=644 fluxbox/init ~/.fluxbox/init
  install_with_prompt --mode=644 fluxbox/keys ~/.fluxbox/keys
  install_with_prompt --mode=644 "$TEMP_DIR/menu" ~/.fluxbox/menu
  install_with_prompt --mode=644 fluxbox/slitlist ~/.fluxbox/slitlist
  install_with_prompt --mode=644 fluxbox/startup ~/.fluxbox/startup
}

function configure_gamemode {
  install_with_prompt --sudo --mode=644 gamemode.ini /etc/gamemode.ini
}

GIT_GPG_KEY_EXPIRE='1y'

function configure_git {
  local name email gpg_key_comment signingkey
  if [[ "$(get_machine_type)" == 'infrastructure' ]]; then
    echo "Infrastructure machine, skipping."
    return 0
  fi

  # Name
  if name="$(git config --global user.name)"; then
    echo "user.name is $name"
  else
    printf 'Enter git name: '
    read -re name
  fi

  # Email
  if email="$(git config --global user.email)"; then
    echo "user.email is $email"
  else
    printf 'Enter git email: '
    read -re email
  fi

  gpg_key_comment="$(get_machine_id)-git"

  # Signing key
  if signingkey="$(git config --global user.signingkey)"; then
    echo "user.signingkey is $signingkey (already set)"
  elif signingkey="$(get_gpg_key_fingerprint "$name" "$gpg_key_comment" "$email")"; then
    echo "user.signingkey is $signingkey (detected via gpg)"
  else
    echo "Unable to detect git signing key."
    signingkey="$(generate_gpg_key "$name" "$gpg_key_comment" "$email" "$GIT_GPG_KEY_EXPIRE")"    
    echo "user.signingkey is $signingkey (generated)"
  fi

  # Fill in email and signing key in the file
  sed "s/# populate email/$email/g
    s/# populate signingkey/$signingkey/g" gitconfig > "$TEMP_DIR/gitconfig"
  install_with_prompt --mode=644 "$TEMP_DIR/gitconfig" ~/.gitconfig

  if [[ "$(get_machine_type)" == 'work' ]]; then
    echo 'Work machine, skipping github SSH key generation.'
    return 0
  fi
  # Generate ssh key for github
  generate_ssh_key "$(hostname)-github" ~/.ssh/github
}

I3_START_MARKER="### PRIMARY ONLY START MARKER ###"
I3_END_MARKER="### PRIMARY ONLY END MARKER ###"

function configure_i3 {
  if [[ "$(get_machine_type)" =~ ^(work|infrastructure)$ ]]; then
    echo 'Work or infrastructure machine, skipping.'
    return 0
  elif [[ ! -d "$HOME/.config/i3" ]]; then
    echo 'No i3 directory, skipping.'
    return 0
  fi

  # Create copy of primary config with primary-only blocks taken out
  local secondary_config
  secondary_config="$(mktemp)"
  cp i3/i3status-rs-config.toml "$secondary_config"
  sed --in-place --null-data "s/$I3_START_MARKER.*$I3_END_MARKER//g" "$secondary_config"

  install_with_prompt --mode=644 i3/config ~/.config/i3/config
  install_with_prompt --mode=644 i3/i3status-rs-config.toml ~/.config/i3/i3status-rs-config-primary.toml
  install_with_prompt --mode=644 "$secondary_config" ~/.config/i3/i3status-rs-config-secondary.toml

  rm "$secondary_config"
}

function configure_nano {
  if [[ -f /etc/nanorc ]]; then
    install_with_prompt --sudo --mode=644 nanorc /etc/nanorc
  fi
  if [[ -f /etc/nano/nanorc ]]; then
    install_with_prompt --sudo --mode=644 nanorc /etc/nano/nanorc
  fi
  if [[ -f ~/.nanorc ]]; then
    install_with_prompt --mode=644 nanorc ~/.nanorc
  fi
}

function configure_neovim {
  install_with_prompt --parents-mode=755 --mode=644 neovim.init.lua ~/.config/nvim/init.lua
}

function configure_password {
  if [[ "$(get_machine_type)" == 'work' ]]; then
    echo 'Work machine, skipping.'
    return 0
  fi
  if user_has_bad_password "$(whoami)"; then
    passwd
  fi
}

function configure_scripts {
  local sources source destination
  mapfile -t sources < <(
    find scripts/ -type f \
      -wholename 'scripts/common/*' -or -wholename "scripts/$(get_machine_type)/*"
  )
  for source in "${sources[@]}"; do
    destination="/usr/local/bin/$(basename "$source")"
    install_with_prompt --sudo --mode=755 --owner=root --group=root \
      "$source" "$destination"
  done
}

function configure_shells {
  install_with_prompt --mode=644 shells/profile ~/.profile
  install_with_prompt --mode=644 shells/bashrc ~/.bashrc
  install_with_prompt --mode=644 shells/zshrc ~/.zshrc
  install_with_prompt --sudo --mode=755 shells/health-check.sh /etc/profile.d/health-check.sh
}

function configure_ssh {
  if [[ "$(get_machine_type)" =~ ^(work|infrastructure)$ ]]; then
    echo 'Work or infrastructure machine, skipping.'
    return 0
  fi

  cat sshconfig > ~/.ssh/config_temp
  if [[ -f ~/.ssh/config.custom ]]; then
    cat ~/.ssh/config.custom >> ~/.ssh/config_temp
  fi
  install_with_prompt --mode=600 -D ~/.ssh/config_temp ~/.ssh/config
  rm ~/.ssh/config_temp

  generate_ssh_key localhost ~/.ssh/localhost
  append_line_with_prompt "$(cat ~/.ssh/localhost.pub)" ~/.ssh/authorized_keys
}

function configure_systemd {
  local locks lock system_units user
  if [[ "$(get_machine_type)" != "personal" ]]; then
    echo 'Non-person machine, skipping'
    return 0
  fi

  locks=(/run/lock/backup.lock)
  for lock in "${locks[@]}"; do
    create_empty_file_with_prompt --sudo "$lock"
  done

  # Figure out what units we care about
  mapfile -t system_units < <(find systemd/ -maxdepth 1 -type f -printf "%f\n")
  mapfile -t user_units < <(find systemd/user/ -maxdepth 1 -type f -printf "%f\n")

  # Install unit files
  for unit in "${system_units[@]}"; do
    install_with_prompt --sudo --mode=644 --owner=root --group=root "systemd/$unit" "/etc/systemd/system/$unit" 
  done
  for unit in "${user_units[@]}"; do
    install_with_prompt --sudo --mode=644 --owner=root --group=root "systemd/user/$unit" "/etc/systemd/user/$unit" 
  done

  echo 'Reloading systemd daemons...'
  sudo systemctl daemon-reload

  echo 'Enabling units...'
  for unit in "${system_units[@]}"; do
    case "$unit" in
    *.service)
      if ! contains "${system_units[@]}" "${unit//.service/.timer}"; then
        sudo systemctl enable --now "$unit"
      fi;;
    *.timer)
      sudo systemctl enable "$unit";;
    *)
      error "Unsupported systemd unit type for unit $unit."
    esac
  done

  for unit in "${user_units[@]}"; do
    case "$unit" in
    *.service)
      if ! contains "${user_units[@]}" "${unit//.service/.timer}"; then
        systemctl --user enable --now "$unit"
      fi;;
    *.timer)
      systemctl --user enable "$unit";;
    *)
      error "Unsupported systemd unit type for unit $unit."
    esac
  done
}

function configure_x {
  local sources source dest
  if [[ "$(get_machine_type)" =~ ^(work|infrastructure)$ ]]; then
    echo 'Work or infrastructure machine, skipping.'
    return 0
  fi
  install_with_prompt --mode=644 x/user-dirs.dirs ~/.config/user-dirs.dirs
  install_with_prompt --mode=644 x/Xdefaults ~/.Xdefaults
  install_with_prompt --mode=644 x/xinitrc ~/.xinitrc
  install_with_prompt --mode=644 x/Xresources ~/.Xresources
  mapfile -t sources < <(find "x/polkit/" -type f)
  for source in "${sources[@]}"; do
    dest="/etc/polkit-1/rules.d/$(basename "$source")"
    install_with_prompt --sudo --mode=750 --owner=root --group=polkitd "$source" "$dest"
  done
}

function configure_yay {
  install_with_prompt --parents-mode=755 --mode=644 yay.init.lua ~/.config/yay/init.lua
}

main "$@"
