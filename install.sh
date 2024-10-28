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

function configure_bash {
  install_with_prompt --mode=644 bash/bashrc ~/.bashrc
}

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
    printf 'Extension list up to date.\n'
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
    grep '# autoexec' fluxbox/fluxbox/menu \
    | sed --regexp-extended "s/$regex/\3/g" \
    | grep_if_command
  )

  # Uncomment 'autoexec' lines of commands that exist, then remove the rest.
  regex="^(\s*)#\s*autoexec\s*(.*\{($(join '|' "${apps[@]}"))\})\s*$"
  sed --regexp-extended "s/$regex/\1\2/g" fluxbox/fluxbox/menu \
  | grep --invert-match '#\s*autoexec' \
  > "$TEMP_DIR/menu"

  # Copy files
  install_with_prompt --mode=644 fluxbox/fluxbox/styles/black ~/.fluxbox/styles/black
  install_with_prompt --mode=644 fluxbox/fluxbox/apps ~/.fluxbox/apps
  install_with_prompt --mode=644 fluxbox/fluxbox/groups ~/.fluxbox/groups
  install_with_prompt --mode=644 fluxbox/fluxbox/init ~/.fluxbox/init
  install_with_prompt --mode=644 fluxbox/fluxbox/keys ~/.fluxbox/keys
  install_with_prompt --mode=644 "$TEMP_DIR/menu" ~/.fluxbox/menu
  install_with_prompt --mode=644 fluxbox/fluxbox/slitlist ~/.fluxbox/slitlist
  install_with_prompt --mode=644 fluxbox/fluxbox/startup ~/.fluxbox/startup
  install_with_prompt --mode=644 fluxbox/user-dirs.dirs ~/.config/user-dirs.dirs
  install_with_prompt --mode=644 fluxbox/xinitrc ~/.xinitrc
  install_with_prompt --mode=644 fluxbox/Xdefaults ~/.Xdefaults
  install_with_prompt --mode=644 fluxbox/Xresources ~/.Xresources
}

function configure_git {
  local email signingkey

  # Email
  if ! email="$(git config --global user.email)"; then
    printf 'Enter git email: '
    read -re email
  fi

  # Signing key
  if ! signingkey="$(git config --global user.signingkey)"; then
    printf 'Enter git signing key fingerprint: '
    read -re signingkey
  fi

  # Fill in email and signing key in the file
  sed "s/# populate email/$email/g
    s/# populate signingkey/$signingkey/g" gitconfig > "$TEMP_DIR/gitconfig"
  install_with_prompt --mode=644 "$TEMP_DIR/gitconfig" ~/.gitconfig
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

function configure_scripts {
  local source destination
  for source in scripts/*; do
    destination="/usr/local/bin/$(basename "$source")"
    install_with_prompt --sudo --mode=755 --owner=root --group=root \
      "$source" "$destination"
  done
}

function configure_ssh {
  install_with_prompt --mode=600 -D sshconfig ~/.ssh/config
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

main
