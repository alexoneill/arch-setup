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
    if [[ "$#" != "2" ]]
    then
      ln
      return
    fi

    # Handle various edge cases
    mkdir_tell $(dirname $2)

    readlink -f $1
    readlink -f $2

    if [[ ! -h "$2" ]]
    then
      if [[ -e "$2" ]]
      then
        rm -rf "$2"
      fi

      tell "ln -s $1 $2"
      ln -s $1 $2
    elif [[ "$(readlink -f $2)" != "$(readlink -f $1)" ]]
    then
      rm "$2"
      
      tell "ln -s $1 $2"
      ln -s $1 $2
    fi
  }
}

# Designed for sourcing
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "0" ]] && sourced $@
