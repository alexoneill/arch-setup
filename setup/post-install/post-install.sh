#!/bin/bash
# post-install.sh
# aoneill - 07/27/16

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function init() {
  for file in $(find "$DIR" -maxdepth 1 -type f -name "*-*" | sort); do
    [[ -x "$file" ]] && echo "$file"
  done
}

function sourced() {
  SETUP="$(cd "$DIR/../" && pwd)"
  source "$SETUP/common/util/util.sh"

  if [[ "$1" == "all" ]]; then
    for file in $(find "$DIR" -maxdepth 1 -type f -name "*-*" | sort); do
      [[ -x "$file" ]] && echo source "$file"
    done
  fi
}

# Run init only when run
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "1" ]] && init $@
[[ "$EXEC" == "0" ]] && sourced $@
