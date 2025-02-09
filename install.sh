#!/usr/bin/env bash
set -euo pipefail

REPO_PATH="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

# Helper functions are in another file because there's a lot of them.
# shellcheck disable=SC1091
source "$REPO_PATH/helpers.sh"

function main {
  local tool
  fail_if_running_as_root
  trap cleanup EXIT
  echo 'Creating temporary directory...'
  TEMP_DIR="$(mktemp --directory)"
  cd "$REPO_PATH" || exit
  for tool in $(get_configure_functions); do
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
  local command config_dir
  if [[ -d "$HOME/.config/VSCodium" ]]; then
    command='codium'
    config_dir="$HOME/.config/VSCodium"
  elif [[ -d "$HOME/.config/Code - OSS" ]]; then
    command='code'
    config_dir="$HOME/.config/Code - OSS"
  else
    error "Unable to determine code config directory."
  fi

  install_with_prompt --mode=644 -D code/settings.json "$config_dir/User/settings.json"

  mapfile -t missing_extensions < <(
    comm -23 <(sort code/extensions) \
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
  if [[ ! -d "$HOME/.fluxbox" ]]; then
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

GIT_GPG_KEY_EXPIRE='1y'

function configure_git {
  local name email gpg_key_comment signingkey

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

  # Generate ssh key for github
  generate_ssh_key "$(hostname)-github" ~/.ssh/github
}

function configure_i3 {
  if [[ ! -d "$HOME/.config/i3" ]]; then
    echo 'No i3 directory, skipping.'
    return 0
  fi
  install_with_prompt --mode=644 i3/config ~/.config/i3/config
  install_with_prompt --mode=644 i3/i3status-rs-config.toml ~/.config/i3/i3status-rs-config.toml
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

function configure_password {
  if user_has_bad_password "$(whoami)"; then
    passwd
  fi
}

function configure_scripts {
  local source destination
  for source in scripts/*; do
    destination="/usr/local/bin/$(basename "$source")"
    install_with_prompt --sudo --mode=755 --owner=root --group=root \
      "$source" "$destination"
  done
}

function configure_shells {
  install_with_prompt --mode=644 shells/profile ~/.profile
  install_with_prompt --mode=644 shells/bashrc ~/.bashrc
  install_with_prompt --mode=644 shells/zshrc ~/.zshrc
}

function configure_ssh {
  install_with_prompt --mode=600 -D sshconfig ~/.ssh/config
  generate_ssh_key localhost ~/.ssh/localhost
  append_line_with_prompt "$(cat ~/.ssh/localhost.pub)" ~/.ssh/authorized_keys
}

function configure_vim {
  if [[ -f /etc/vimrc ]]; then
    install_with_prompt --sudo --mode=644 --owner=root --group=root vimrc /etc/vimrc
  fi
  if [[ -f /etc/vim/vimrc ]]; then
    install_with_prompt --sudo --mode=644 --owner=root --group=root -D vimrc /etc/vim/vimrc
  fi
  if [[ -f ~/.vimrc ]]; then
    install_with_prompt --mode=644 vimrc ~/.vimrc
  fi
}

function configure_x {
  local sources source dest
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

main
