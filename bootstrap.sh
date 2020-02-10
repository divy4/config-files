#!/usr/bin/env bash
set -e

BAD_PASSWORDS=(password qwerty 12345)
NAME='Dan Ivy'

function main {
  if [[ ! -d /etc/X11/ ]] || xhost 2&> /dev/null; then
    echo_tty 'Running first time setup...'
    populate_passwords
    populate_git
    populate_fluxbox
  else
    echo "Please start an X session before running first time setup."
    return 1
  fi
}

####################
# Population Areas #
####################

function populate_passwords {
  if user_has_a_bad_password "$(whoami)"; then
    echo_tty "Populating password for $(whoami)..."
    passwd
  fi
  if user_has_a_bad_password root; then
    echo_tty "Populating password for root..."
    obscure_password root || true # Don't fail on error
  fi
}

function populate_git {
  local email fingerprint comment
  if ! is_populated ~/.gitconfig; then
    echo_tty 'Populating git config...'
    email="$(read_with_confirm email)"
    comment="$(get_machine_id)-git"
    fingerprint="$(generate_gpg_key "$NAME" "$comment" "$email" 1d)"
    generate_ssh_key "$comment" ~/.ssh/git
    populate ~/.gitconfig email "$email"
    populate ~/.gitconfig signingkey "$fingerprint"
  fi
}

function populate_fluxbox {
  local full third tenth mappings
  if [[ -f ~/.fluxbox/keys ]]; then
    echo_tty 'Populating Fluxbox config...'
    full="$(get_screen_width)"
    third=$((full / 3))
    tenth=$((full / 10))
    mappings=(\
      23% $((third - tenth))
      24% $((full - 2 * third - tenth))
      33% "$third"
      34% $((full - 2 * third))
      43% $((third + tenth))
      44% $((full - 2 * third + tenth))
      56% $((2 * third - tenth))
      57% $((full - third - tenth))
      66% $((2 * third))
      67% $((full - third))
      76% $((2 * third + tenth))
      77% $((full - third + tenth))
    )
    keys="$(cat ~/.fluxbox/keys)"
    for ((i=0; i<${#mappings[@]}; i=i+2)); do
      keys="$(echo "$keys" | sed "s/${mappings[i]}/${mappings[i+1]}/g")"
    done
    echo "$keys" > ~/.fluxbox/keys
    echo_tty 'Please reload Fluxbox configs to see proper settings'
  fi
}

#############
# Passwords #
#############

function user_has_a_bad_password {
  local password
  for password in "${BAD_PASSWORDS[@]}"; do
    if echo "$password" | timeout 1 su --command='exit 0' "$1" 2> /dev/null
    then
      return 0
    fi
  done
  return 1
}

function obscure_password {
  local user password
  user="${1?Please specify a user}"
  password="$(generate_password 256)"
  sudo bash -c "echo -e '$password\n$password\n' | passwd '$user'"
}

function generate_password {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9-_' | fold -w "$1" | head -n 1
}

#######
# GPG #
#######

function generate_gpg_key {
  local name comment email expire fingerprint
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  expire="${4?Please specify an expiry pattern}"
  fingerprint="$(get_gpg_key_fingerprint "$name" "$comment" "$email" 2> /dev/null)"
  if [[ "$?" -eq 0 ]]; then
    echo_tty "GPG key with fingerprint $fingerprint found. Skipping key generation."
  else
    echo_tty 'Generating GPG key...'
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

#######
# SSH #
#######

function generate_ssh_key {
  local comment path
  comment="${1?Please specify a comment}"
  path="${2?Please specify an output path}"
  if [[ -f "$path" ]]; then
    echo_tty "SSH key $path found. Skipping generation."
  else
    echo_tty "Generating SSH key $path..."
    ssh-keygen -t ed25519 -C "$comment" -f "$path"
  fi
  echo_tty "Public key of $path"
  cat "$path.pub"
}

#####
# X #
#####

function get_screen_height {
  xrandr | grep '\*' | tr 'x' ' ' | awk '{print $2}'
}

function get_screen_width {
  xrandr | grep '\*' | tr 'x' ' ' | awk '{print $1}'
}

##############
# Base Tools #
##############

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

function get_machine_id {
  cat /etc/machine-id
}

function echo_tty {
  echo "$@" > /dev/tty
}

main "$@"
