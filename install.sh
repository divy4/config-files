#!/bin/bash

# settings
BASHRC_SOURCE=bashrc
BASHRC_DESTS=(~/.bashrc)
GITCONFIG_SOURCE=gitconfig
GITCONFIG_DESTS=(~/.gitconfig)
NANORC_SOURCE=nanorc
NANORC_DESTS=(~/.nanorc /etc/nanorc /etc/nano/nanorc)
VIMRC_SOURCE=vimrc
VIMRC_DESTS=(~/.vimrc /etc/vimrc /etc/vim/vimrc)

# functions

function lookup {
  local x="$1"
  local arr=( "${@:2}" )
  local output=-1
  for index in "${!arr[@]}"; do
    if [[ "${x}" = "${arr[$index]}" ]]; then
      output=$index
      break
    fi
  done
  return $output
}

function is_yes {
  local input="$1"
  return $([ "${input,,}" == 'y' ] || [ "${input,,}" == "yes" ])
}

function is_no {
  local input="$1"
  return $([ "${input,,}" == 'n' ] || [ "${input,,}" == "no" ])
}

function confirm {
  local msg="$1"
  if [ "$msg" != "" ]; then
    msg="$msg "
  fi
  local output=-1
  while [ $output -eq -1 ]; do
    echo -n "$msg(y/n) "
    local input
    read input
    if is_yes "$input"; then
      output=0
    elif is_no "$input"; then
      output=1
    fi
  done
  return $output
}

function select_option {
  local msg="$1"
  local options=( "${@:2}" )
  if [ ${#options[@]} -eq 0 ]; then
    (>&2 echo "select_option requires at least 2 arguments")
    exit 1
  elif [ ${#options[@]} -eq 1 ]; then

    return 0
  fi
  if [ "$msg" != "" ]; then
    echo "$msg"
  fi
  local num=0
  local selection=""
  select selection in "${options[@]}"; do
    case "$selection" in
      "")
        echo "Invalid option"
        ;;
      *)
        break
        ;;
    esac
  done
  lookup "$selection" "${options[@]}"
  return $!
}

function install {
  local source="$1"
  local dest_options=( "${@:2}" )
  if confirm "Install $source?"; then
    select_option "Select where to install $source:" "${dest_options[@]}"
    local dest="${dest_options[$?]}"
    echo "Copying $source to $dest"
    cp $source $dest
  fi
}


# installation
install "$BASHRC_SOURCE" "${BASHRC_DESTS[@]}"
install "$GITCONFIG_SOURCE" "${GITCONFIG_DESTS[@]}"
install "$NANORC_SOURCE" "${NANORC_DESTS[@]}"
install "$VIMRC_SOURCE" "${VIMRC_DESTS[@]}"

