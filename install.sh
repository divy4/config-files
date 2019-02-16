#!/bin/bash

# settings
install_nanorc_to_all='yes'
install_vimrc_to_all='yes'

bashrc_source=bashrc
bashrc_dist=~/.bashrc
gitconfig_source=gitconfig
gitconfig_dist=~/.gitconfig
nanorc_source=nanorc
nanorc_dist=~/.nanorc
nanorc_dist_all=/etc/nanorc
vimrc_source=vimrc
vimrc_dist=~/.vimrc
vimrc_dist_all=/etc/vim/vimrc

# functions

function is_yes {
  if [ "${1,,}" == 'y' ] || [ "${1,,}" == "yes" ]; then
    return 0
  else
    return 1
  fi
}

function is_no {
  if [ "${1,,}" == 'n' ] || [ "${1,,}" == "no" ]; then
    return 0
  else
    return 1
  fi
}

function confirm {
  msg="$1"
  if [ "$msg" != "" ]; then
    msg="$msg "
  fi
  output=-1
  while [ $output -eq -1 ]; do
    echo -n "$msg(y/n) "
    read input
    if is_yes "$input"; then
      output=0
    elif is_no "$input"; then
      output=1
    fi
  done
  return $output
}

# installation
cp $bashrc_source $bashrc_dist
echo "Remember to call 'source ~/.bashrc'!"
cp $gitconfig_source $gitconfig_dist
if confirm "Install nanorc for all users?"; then
  sudo cp $nanorc_source $nanorc_dist_all
else
  cp $nanorc_source $nanorc_dist
fi
if confirm "Install vimrc for all users?"; then
  sudo cp $vimrc_source $vimrc_dist_all
else
  cp $vimrc_source $vimrc_dist
fi

