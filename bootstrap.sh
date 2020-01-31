#!/usr/bin/env bash
set -e

NAME='Dan Ivy'

function main {
  echo 'Configuring first time setup...'
  populate_password
  populate_git
}

function populate_password {
  if my_password_is_bad; then
    echo "Populating password"
    passwd
  fi
}

function populate_git {
  local email fingerprint
  if ! is_populated ~/.gitconfig; then
    echo 'Populating git config...'
    email="$(read_with_confirm email)"
    echo 'Please enter a password for your git signing key'
    sleep 1
    gpg --batch --generate-key \
      <(generate_gpg_script "$NAME" git "$email" 1d)
    fingerprint="$(get_gpg_key_fingerprint "$NAME" git "$email")"
    populate ~/.gitconfig email "$email"
    populate ~/.gitconfig signingkey "$fingerprint"
    echo 'Generated key public block:'
    get_gpg_key_public_block "$NAME" git "$email"
  fi
}

function get_gpg_key_public_block {
  local name email comment expire
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  gpg --armor --export "$name ($comment) <$email>"
}

function get_gpg_key_fingerprint {
  local name email comment expire
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  gpg --armor --fingerprint --keyid-format LONG --with-colons \
    "$name ($comment) <$email>" \
    | grep fpr \
    | grep --only-matching '[0-9A-Fa-f]\{40\}'
}

function generate_gpg_script {
  local name comment email expire
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  expire="${4?Please specify an expiry pattern}"
  cat << EOF
%ask-passphrase
Key-Type: RSA
Key-Length: 4096
Name-Real: $name
Name-Comment: $comment
Name-Email: $email
Expire-Date: $expire
EOF
}

function populate {
  sed --in-place --expression="s/# populate $2$/$3/g" "$1"
}

function is_populated {
  ! grep --quiet '# populate \w\+$' "$1"
}

function read_with_confirm {
  local value
  while [[ -z "$confirmed" ]]; do
    if [[ "$#" -ne 0 ]]; then
      echo_tty 'Input' "$@"
    fi
    read -r value
    if confirm "Confirm '$value'?"; then
      confirmed=0
    fi
  done
  echo "$value"
}

function confirm {
  local answer
  if [[ "$#" -ne 0 ]]; then
    echo_tty "$@"
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
      return 0
    fi
  done
  return 1
}

function echo_tty {
  echo "$@" > /dev/tty
}

main "$@"
