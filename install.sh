#!/usr/bin/env bash

set -e

function main {
  local config_functions interactive config_function name
  config_functions=("$@")
  interactive=false
  if [[ -z "$config_functions" ]]; then
    mapfile -t config_functions < <(get_config_functions)
    interactive=true
  fi
  for config_function in "${config_functions[@]}"; do
    if [[ "$interactive" == 'false' ]] \
        || confirm_config "$config_function"; then
      "config_$config_function"
    fi
  done
}

function config_bash {
  copy_file bashrc ~/.bashrc
}

function config_conemu {
  copy_file ConEmu.xml "$APPDATA/ConEmu.xml"
}

function config_fluxbox {
  copy_directory fluxbox ~/.fluxbox
  copy_file fluxbox_xinitrc ~/.xinitrc
  copy_file fluxbox_Xresources ~/.Xresources
}

function config_git {
  copy_file gitconfig ~/.gitconfig
}

function config_nano {
  if is_root; then
    copy_file nanorc /etc/nanorc /etc/nano/nanorc
  else
    copy_file nanorc ~/.nanorc
  fi
}

function config_vim {
  if is_root; then
    copy_file vimrc /etc/vimrc /etc/vim/vimrc
  else
    copy_file vimrc ~/.vimrc
  fi
}

function get_config_functions {
  declare -F \
    | grep --only-matching --perl-regexp '(?<=\s)config_\w*$' \
    | sed 's/config_//g' \
    | sort --ignore-case
}

function copy_file {
  local source targets target
  source="$1"
  targets=("${@:2}")
  target="$(select_option "Select where to install config:" "${targets[@]}")"
  cp "$source" "$target"
}

function copy_directory {
  local source targets target
  source="$1"
  targets=("${@:2}")
  target="$(select_option "Select where to install config:" "${targets[@]}")"
  cp -r "$source/"* "$target"
}

function select_option {
  local message options selection
  message="$1"
  options=("${@:2}")
  if [ "${#options[@]}" -eq 0 ]; then
    echo_err 'select_option requires at least 1 argument'
    return 1
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

function confirm_config {
  confirm "Configure $1"
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
