#!/usr/bin/env bash

# General Helpers

function fail_if_running_as_root {
  if [[ "$EUID" -eq 0 ]]; then
    error "Running as root is not supported."
  fi
}

function get_configure_functions {
 declare -F \
  | grep --only-matching --perl-regexp '(?<=\sconfigure_)\w*$' \
  | sort --ignore-case
}

# Same as the install command, but includes a git diff and user prompt before
# making changes. Includes an additional flag, --sudo, which runs command as
# root.
function install_with_prompt {
  local sudo_enabled arguments argument source target
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

  if [[ ! -a "$source" ]]; then
    error "Source $source does not exist."
  fi

  echo -n "Installing $target ... "
  # Skip if it wouldn't change anything.
  if compare_paths "$target" "$source"; then
    echo "no changes needed."
    return
  fi
  # ...or if the user says no.
  if ! confirm 'Install?'; then
    return
  fi

  # Run install command as root or as current user
  if [[ "$sudo_enabled" == 'true' ]]; then
    sudo install "${arguments[@]}"
  else
    install "${arguments[@]}"
  fi
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

# Output

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

# Print an error and return unsuccessfully.
function error {
  echo_err 'Error:' "$@"
  return 1
}

# Same as echo command, but to stderr.
function echo_err {
 >&2 echo "$@"
}

# Misc

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
