#!/usr/bin/env bash

set -e

function main {
  echo 'Configuring first time setup...'
  if my_password_is_bad; then
    passwd
  fi
  populate ~/.gitconfig email
}

function populate {
  local file variable value confirmed
  file="${1?Please specify a file}"
  variable="${2?Please specify a variable}"
  value="$3"
  if contains_populate_comment "$file" "$variable"; then
    if [[ -z "$value" ]]; then
      while [[ -z "$confirmed" ]]; do
        echo "Assign $variable in $file:"
        read -r value
        if confirm "Confirm assigning $variable to '$value'?"; then
          confirmed=0
        fi
      done
    fi
    replace_populate_comment "$file" "$variable" "$value"
  fi
}

function replace_populate_comment {
  sed --in-place --expression="s/# populate $2$/$3/g" "$1"
}

function contains_populate_comment {
  grep --quiet "# populate $2$" "$1"
}

function confirm {
  local answer
  if [[ "$#" -ne 0 ]]; then
    echo "$@"
  fi
  while [[ ! "$answer" =~ ^((yes)|(y)|(no)|(n))$ ]]; do
    read -r answer
    answer="${answer,,}"
  done
  [[ "$answer" =~ ^(yes)|(y)$ ]]
}

function my_password_is_bad {
  for password in password qwerty 12345 123456; do
    if echo "$password" | timeout 1 su --command='exit 0' "$(whoami)" 2> /dev/null
    then
      echo "Please change your password (something better than $password!)"
      return 0
    fi
  done
  return 1
}

main "$@"
