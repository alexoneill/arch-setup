#!/bin/bash
# fs.sh
# aoneill - 07/27/16

_FS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  function expand_glob() {
    list=($1)
    echo "${list[@]}"
  }

  function safe_ln() {
    if [[ "$#" != "2" ]]; then
      ln
      return
    fi

    # Handle various edge cases
    if ! [[ -d "$(dirname $2)" ]]; then
      tell mkdir -p $(dirname $2)
    fi

    if [[ ! -h "$2" ]]; then
      if [[ -e "$2" ]]; then
        tell rm -rf "$2"
      fi

      tell ln -s $1 $2
    elif [[ "$(readlink -f $2)" != "$(readlink -f $1)" ]]; then
      tell rm "$2"
      tell ln -s $1 $2
    fi
  }
}

# Designed for sourcing
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "0" ]] && sourced $@
