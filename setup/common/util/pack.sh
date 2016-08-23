#!/bin/bash
# pack.sh
# aoneill - 07/27/16

# Local directory the script is in
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  function pack_folder() {
    basename "$1" | sed -e "s/^[0-9]*-//g" | sed -e "s/\.[a-zA-Z0-9]*$//g"
  }
} 

# Designed for sourcing
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "0" ]] && sourced $@
