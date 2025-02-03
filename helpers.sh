#!/usr/bin/env bash
set -euo pipefail

# General Helpers

function get_configure_functions {
 declare -F \
  | grep --only-matching --perl-regexp '(?<=\sconfigure_)\w*$' \
  | sort --ignore-case
}

# Same as the install command, but includes a git diff and user prompt before
# making changes. Includes an additional flag, --sudo, which runs command as
# root.
function install_with_prompt {
  local sudo_enabled arguments argument source target command
  if [[ "$#" -lt 2 ]]; then
    error "install_with_prompt requires at least 2 arguments"
  fi

  sudo_enabled='false'
  arguments=()
  # Find source/target
  for argument in "$@"; do
    case "$argument" in
    # Find --sudo flag
    --sudo)
      sudo_enabled='true'
      continue;;
    # Skip if argument is a flag
    -*)
      arguments+=("$argument")
      continue;;
    *)
      arguments+=("$argument")
      # First non-flag is the source, second is the target
      if [[ -z "${source:-}" ]]; then
        source="$argument"
      else
        target="$argument"
      fi
    esac
  done

  # Escalate if --sudo was passed
  if [[ "$sudo_enabled" == 'true' ]]; then
    # Generate bash script that executes this function
    command="source ${BASH_SOURCE[0]}; install_with_prompt"
    for argument in "${arguments[@]}"; do
      # Escape arguments with single quotes
      command+=" '$argument'"
    done
    # Execute command as sudo
    sudo bash -c "$command"
    return
  fi

  # Throw error if the source doesn't exist
  if [[ ! -a "$source" ]]; then
    error "Source $source does not exist."
  fi

  echo -n "Installing $target ... "
  # Skip if it wouldn't change anything.
  if compare_paths "$target" "$source"; then
    echo "no changes needed."
    return
  # ...or if the user says no.
  elif ! confirm 'Install?'; then
    return
  fi

  # Run install command
  install "${arguments[@]}"
}

# Given a string and a file, append the string to the file if it isn't already
# in the file.
function append_line_with_prompt {
  local string file
  string="$1"
  file="$2"
  echo -n "Updating $2 ... "
  # Skip if the line is already present.
  if grep --fixed-strings --line-regexp --quiet "$string" "$file"; then
    echo "no changes needed."
    return
  fi

  # Show changes being made
  compare_paths "$file" <(cat "$file" <(echo "$string")) || true

  # Skip if user rejects change
  if ! confirm 'Update?'; then
    return
  fi

  # Make the change!
  echo "$string" >> "$file"
}

# Human input

# Given a prompt, prompt the user yes or no.
function confirm {
  [[ "$(prompt_with_options "$1" yes no)" == "yes" ]]
}

# Given a prompt and an array of options, prompt the user until they enter one
# of the options.
function prompt_with_options {
  local prompt options input selection
  prompt="$1"
  options=("${@:2}")
  while true; do
    echo_err -n "$prompt" "($(join / "${options[@]}")) "
    read -r input
    if selection="$(best_guess "$input" "${options[@]}")"; then
      echo "$selection"
      return
    fi
  done
}

# Given a string and an array of options, makes a best attempt guess of what
# string in the array correlates to the first string. Fails if 0 or more than 1
# option match. For example,
# best_guess de abc def ghi
# would return def because de is a prefix of def and no other strings in the
# array.
function best_guess {
  local input options option guess
  # Fail early if nothing is specified
  if [[ "$#" -lt 2 ]]; then
    error 'best_guess requires at least 2 arguments'
  fi
  # Convert everything to lowercase
  input="${1,,}"
  mapfile -t options < <(printf '%s\n' "${@:2}" | tr '[:upper:]' '[:lower:]')
  # Find one option that either matches or starts with the input
  for option in "${options[@]}"; do
    if [[ "$option" == "$input"* ]]; then
      if [[ -z "${guess:-}" ]]; then
        guess="$option"
      # Match already found, so exit early
      else
        return 1
      fi
    fi
  done
  # No match found
  if [[ -z "${guess:-}" ]]; then
    return 1
  fi
  # Match found!
  echo "$guess"
}

# User management

BAD_PASSWORDS=(password qwerty 12345)

# Given a username, returns successfully if that user has a bad password.
function user_has_bad_password {
  local user password
  user="${1?Please specify a user}"
  echo_err -n "Attempting to crack $user's password... "
  for password in "${BAD_PASSWORDS[@]}"; do
    if echo "$password" | timeout 0.1 su --command='true' "$user" 2> /dev/null
    then
      echo_err "cracked password successfully."
      return
    fi
  done
  echo_err "password is secure."
  return 1
}

# GPG

# Given a name, comment, email, and expiry pattern, generate a gpg key and
# return it's fingerprint.
function generate_gpg_key {
  local name comment email expire fingerprint
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  expire="${4?Please specify an expiry pattern}"
  echo_err 'Generating new gpg key...'

  fingerprint="$(get_gpg_key_fingerprint "$name" "$comment" "$email")"
  if [[ -n "$fingerprint" ]]; then
    error "Key matching name/comment/email already exists: $fingerprint"
  fi

  gpg --batch --generate-key \
    <(generate_gpg_script "$name" "$comment" "$email" "$expire") \
    > /dev/tty
  
  get_gpg_key_fingerprint "$name" "$comment" "$email"
}

# Given the same inputs as generate_gpg_key, generate the gpg script to
# generate that key.
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

# Given a name, comment, and email, return the fingerprint of the corresponding
# gpg key.
function get_gpg_key_fingerprint {
  local name email comment
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  gpg --armor --fingerprint --keyid-format LONG --with-colons \
    "$name ($comment) <$email>" 2> /dev/null \
    | grep fpr \
    | grep --only-matching '[0-9A-Fa-f]\{40\}'
}

# SSH

# Given a comment and path, generate an ssh key
function generate_ssh_key {
  local comment path
  comment="${1?Please specify a comment}"
  path="${2?Please specify an output path}"
  echo -n "Generating SSH key $path ... "
  if [[ -f "$path" ]]; then
    echo_err "key already exists, skipping."
    return
  fi
  ssh-keygen -t ed25519 -C "$comment" -f "$path"
}

# Output and errors

function fail_if_running_as_root {
  if [[ "$EUID" -eq 0 ]]; then
    error "Running as root is not supported."
  fi
}

# Print an error and return unsuccessfully.
function error {
  echo_err 'Error:' "$@"
  exit 1
}

# Same as echo command, but to stderr.
function echo_err {
 >&2 echo "$@"
}

function print_header {
  local input input_length terminal_width prefix_length suffix_length
  input="$*"
  input_length="${#input}"
  terminal_width="${COLUMNS:-50}"

  prefix_length=$(( (terminal_width - input_length - 2) / 2 ))
  suffix_length=$(( terminal_width - prefix_length - input_length - 2 ))

  printf -- '-%.0s' $(seq "$prefix_length")
  printf ' %s ' "$input"
  printf -- '-%.0s' $(seq "$suffix_length")
  printf '\n'
}

# Misc

# Prints an unique ID of this machine.
function get_machine_id {
  if [[ -f /etc/machine-id ]]; then
    cat /etc/machine-id
  else
    echo "$HOSTNAME"
  fi
}

# Assuming every line is a command, only returns the lines that correspond to
# commands on the system.
function grep_if_command {
  local command
  while read -r command; do
    if command -v "$command" > /dev/null; then
      echo "$command"
    fi
  done
}

# Compares two files or directories. Returns 0 if no changes are present.
function compare_paths {
  local a b
  if [[ -a "$1" ]]; then
    a="$1"
  else
    a=/dev/null
  fi
  if [[ -a "$2" ]]; then
    b="$2"
  else
    b=/dev/null
  fi
  git -c color.ui=always diff --no-index --exit-code "$a" "$b"
}

# Similar to python's string.join method.
function join {
  # Nothing inputted, throw an error
  if [[ "$#" -eq 0 ]]; then
    error "Missing joiner string."
  # No array elements, nothing to print
  elif [[ "$#" -eq 1 ]]; then
    return
  fi

  # Always print first element
  printf '%s' "$2"
  # Print additional elements if available
  if [[ "$#" -gt 2 ]]; then
    printf "$1%s" "${@:3}"
  fi
}
