#!/usr/bin/env bash

set -e

paths=(\
  ~/.fluxbox/backgrounds/background.jpg \
  ~/.fluxbox/backgrounds/background.png \
)

function main {
  for path in "$@"; do
    if [[ -f "$path" ]]; then
      echo "Setting background to $path..."
      fbsetbg -a "$path"
      return 0
    fi
  done
}

main "${paths[@]}"