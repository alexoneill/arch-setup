#!/bin/bash
# fs.sh
# aoneill - 07/27/16

_FS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  function expand_glob() {
    list=($@)
    echo "${list[@]}"
  }
  
  function will_safe_ln() {
    [[ "$#" != "2" ]] && return 0

    # If we have to create the destination directory, then we will ln
    ! [[ -d "$(dirname $2)" ]] && return 1

    # If the destination is not a link
    [[ ! -h "$2" ]] && return 1

    # If the destination is the wrong link
    [[ "$(readlink -f $2)" != "$(readlink -f $1)" ]] && return 1

    return 0
  }

  function safe_ln() {
    # Did not pass enough arguments
    if [[ "$#" != "2" ]]; then
      ln
      return
    fi

    # Make the destination directory
    if ! [[ -d "$(dirname $2)" ]]; then
      tell mkdir -p $(dirname $2)
    fi

    # See if the destination is a link already
    if [[ ! -h "$2" ]]; then
      # Check to see if it is a regular file
      if [[ -e "$2" ]]; then
        # Remove it
        tell rm "$2"
      fi

      # Properly link
      tell ln -s $1 $2
    elif [[ "$(readlink -f $2)" != "$(readlink -f $1)" ]]; then
      # Remove the old link
      tell rm "$2"

      # Update the link
      tell ln -s $1 $2
    fi
  }
}

# Designed for sourcing
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "0" ]] && sourced $@
