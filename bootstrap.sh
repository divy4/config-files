#!/usr/bin/env bash
set -e

NAME='Dan Ivy'

function main {
  echo_tty 'Configuring first time setup...'
  populate_password
  populate_git
}

function populate_password {
  if my_password_is_bad; then
    echo_tty "Populating password..."
    passwd
  fi
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

function populate_git {
  local email fingerprint
  if ! is_populated ~/.gitconfig; then
    echo_tty 'Populating git config...'
    email="$(read_with_confirm email)"
    fingerprint="$(generate_gpg_key "$NAME" git "$email" 1d)"
    populate ~/.gitconfig email "$email"
    populate ~/.gitconfig signingkey "$fingerprint"
  fi
}

function generate_gpg_key {
  local name comment email expire fingerprint
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  expire="${4?Please specify an expiry pattern}"
  echo_tty 'Generating GPG key...'
  fingerprint="$(get_gpg_key_fingerprint "$name" "$comment" "$email" 2> /dev/null)"
  if [[ "$?" -eq 0 ]]; then
    echo_tty "Key with fingerprint $fingerprint found. Skipping key generation."
  else
    gpg --batch --generate-key \
      <(generate_gpg_script "$name" "$comment" "$email" "$expire") \
      > /dev/tty
    fingerprint="$(get_gpg_key_fingerprint "$name" "$comment" "$email")"
  fi
  get_gpg_key_public_block "$fingerprint" > /dev/tty
  echo "$fingerprint"
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

function get_gpg_key_public_block {
  echo_tty 'GPG key public block:'
  gpg --armor --export "$1"
}

function get_gpg_key_fingerprint {
  local name email comment
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  gpg --armor --fingerprint --keyid-format LONG --with-colons \
    "$name ($comment) <$email>" \
    | grep fpr \
    | grep --only-matching '[0-9A-Fa-f]\{40\}'
}

function populate {
  echo_tty "Populating '$2' in file '$1'"
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

function echo_tty {
  echo "$@" > /dev/tty
}

main "$@"
