#!/usr/bin/env bash

set -e

function main {
  local install_functions interactive install_function name
  install_functions=("$@")
  interactive=false
  if [[ -z "$install_functions" ]]; then
    mapfile -t install_functions < <(get_install_functions)
    interactive=true
  fi
  for install_function in "${install_functions[@]}"; do
    if [[ "$interactive" == 'false' ]] \
        || confirm_install "$install_function"; then
      "install_$install_function"
    fi
  done
}

function install_bash {
  copy_file bashrc ~/.bashrc
}

function install_conemu {
  copy_file ConEmu.xml "$APPDATA/ConEmu.xml"
}

function install_fluxbox {
  copy_directory fluxbox ~/.fluxbox
  copy_file fluxbox_xinitrc ~/.xinitrc
  copy_file fluxbox_Xresources ~/.Xresources
}

function install_git {
  copy_file gitconfig ~/.gitconfig
}

function install_nano {
  copy_file nanorc ~/.nanorc /etc/nanorc /etc/nano/nanorc
}

function install_vim {
  copy_file vimrc ~/.vimrc /etc/vimrc /etc/vim/vimrc
}

function get_install_functions {
  declare -F \
    | grep --only-matching --perl-regexp '(?<=\s)install_\w*$' \
    | sed 's/install_//g' \
    | sort --ignore-case
}

function copy_file {
  local source targets target
  source="$1"
  targets=("${@:2}")
  target="$(select_option "Select where to install:" "${targets[@]}")"
  cp_sudo_on_fail "$source" "$target"
}

function copy_directory {
  local source targets target
  source="$1"
  targets=("${@:2}")
  target="$(select_option "Select where to install:" "${targets[@]}")"
  cp_sudo_on_fail -r "$source/"* "$target"
}

function select_option {
  local message options selection
  message="$1"
  options=("${@:2}")
  if [ "${#options[@]}" -eq 0 ]; then
    (>&2 echo 'select_option requires at least 1 argument')
    exit 1
  elif [ "${#options[@]}" -eq 1 ]; then
    selection="${options[0]}"
  else
    echo_tty "$message"
    select selection in "${options[@]}"; do
      case "$selection" in
        "")
          echo_tty "Invalid option"
          ;;
        *)
          break
          ;;
      esac
    done
  fi
  echo "$selection"
}

function cp_sudo_on_fail {
  if ! cp "$@" && confirm 'Copy failed, elevate to sudo?'; then
    sudo cp "$@"
  fi
}

function confirm_install {
  confirm "Install $1"
}

function confirm {
  local message answer input
  message="$1"
  if [ "$message" != "" ]; then
    message="$message "
  fi
  answer=-1
  while [[ "$answer" -eq -1 ]]; do
    echo_tty -n "$message(y/n) "
    read -r input
    if is_yes "$input"; then
      answer=0
    elif is_no "$input"; then
      answer=1
    fi
  done
  return "$answer"
}

function is_yes {
  [[ "${1,,}" =~ ^y(es)?$ ]]
}

function is_no {
  [[ "${1,,}" =~ ^no?$ ]]
}

function is_root {
  [[ "$UID" -eq 0 ]]
}

function echo_tty {
  echo "$@" > /dev/tty
}

function echo_err {
  >&2 echo "$@"
}

main "$@"
