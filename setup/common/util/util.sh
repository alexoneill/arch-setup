#!/bin/bash
# util.sh
# aoneill - 07/26/16

_UTIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  # Source the support
  for file in $(find "$_UTIL_DIR" -type f -not -name "util.sh"); do
    [[ -x "$file" ]] && source "$file"
  done
}

# Designed for sourcing
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "0" ]] && sourced $@
