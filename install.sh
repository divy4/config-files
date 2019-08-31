#!/usr/bin/env bash

set -e

# settings
BASHRC_SOURCE=bashrc
BASHRC_DESTS=(~/.bashrc)
FLUXBOX_SOURCE=fluxbox
FLUXBOX_DESTS=(~/.fluxbox)
GITCONFIG_SOURCE=gitconfig
GITCONFIG_DESTS=(~/.gitconfig)
NANORC_SOURCE=nanorc
NANORC_DESTS=(~/.nanorc /etc/nanorc /etc/nano/nanorc)
VIMRC_SOURCE=vimrc
VIMRC_DESTS=(~/.vimrc /etc/vimrc /etc/vim/vimrc)
XINITRC_SOURCE=xinitrc
XINITRC_DESTS=(~/.xinitrc /etc/X11/xinit/xinitrc)
XRESOURCES_SOURCE=Xresources
XRESOURCES_DESTS=(~/.Xresources)

function main {
  install bashrc      install_file      "$BASHRC_SOURCE"     "${BASHRC_DESTS[@]}"
  install fluxbox     install_directory "$FLUXBOX_SOURCE"    "${FLUXBOX_DESTS[@]}"
  install gitconfig   install_file      "$GITCONFIG_SOURCE"  "${GITCONFIG_DESTS[@]}"
  install nanorc      install_file      "$NANORC_SOURCE"     "${NANORC_DESTS[@]}"
  install vimrc       install_file      "$VIMRC_SOURCE"      "${VIMRC_DESTS[@]}"
  install xinitrc     install_file      "$XINITRC_SOURCE"    "${XINITRC_DESTS[@]}"
  install Xresources  install_file      "$XRESOURCES_SOURCE" "${XRESOURCES_DESTS[@]}"
}

function install {
  local name command args
  name="$1"
  command="$2"
  args=("${@:3}")
  if confirm "Install $name"; then
    "$command" "${args[@]}"
  fi
}

function install_file {
  local source targets target
  source="$1"
  targets=("${@:2}")
  target="$(select_option "Select where to install:" "${targets[@]}")"
  cp_sudo_on_fail "$source" "$target"
}

function install_directory {
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
  if [[ ! "${1,,}" =~ ^y(es)?$ ]]; then
    return 1
  fi
}

function is_no {
  if [[ ! "${1,,}" =~ ^no?$ ]]; then
    return 1
  fi
}

function echo_tty {
  echo "$@" > /dev/tty
}

function echo_err {
  >&2 echo "$@"
}

main "$@"
