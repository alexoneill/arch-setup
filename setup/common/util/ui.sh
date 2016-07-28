#!/bin/bash
# ui.sh
# aoneill - 07/27/16

_UI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  function tell() {
    if [[ "$QUIET" != 1 ]]
    then
      echo $@
      # "$@"
    fi
  }

  function section() {
    in=$1
    cols=80
    textStart=$((($cols - ${#in}) / 2 - 1))
    head=$(printf "%-${cols}s" "#")

    if [[ "$QUIET" != 1 ]]
    then
      echo "${head// /\#}"
      printf "#%*s" $textStart " "
      echo -n $in
      printf "%*s\n" $(($cols - $textStart - ${#in} - 1)) "#"
      echo "${head// /\#}"
    fi
  }

  function pause() {
    if [[ "$QUIET" != 1 ]]
    then
      echo -n "Press ENTER to continue..."
      read ignored
    fi
  }
} 

# Designed for sourcing
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "0" ]] && sourced $@
