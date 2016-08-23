#!/bin/bash
# ui.sh
# aoneill - 07/27/16

_UI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  function tell() {
    if [[ "$QUIET" != "1" ]]; then
      echo $@
    fi
    if [[ "$DRY_RUN" != "1" ]]; then
      $@
    fi
  }

  function tell_eval() {
    if [[ "$QUIET" != "1" ]]; then
      echo "$@"
    fi
    if [[ "$DRY_RUN" != "1" ]]; then
      eval "$@"
    fi
  }
    
  # Global for keeping track of which sections have been shown
  [[ -z "$_UI_SECTION_TITLES" ]] && _UI_SECTION_TITLES="$(mktemp)"

  function section() {
    in="$@"

    # Skip if the section has already been shown
    [[ -n "$(grep "$in" "$_UI_SECTION_TITLES")" ]] &&
      return
    echo "$in" >> "$_UI_SECTION_TITLES"

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

  function minor_section() {
    in="$@"

    cols=80
    textStart=$((($cols - ${#in}) / 2))
    head=$(printf "%-${cols}s" " ")

    if [[ "$QUIET" != 1 ]]
    then
      # Start with a new line
      echo

      printf "%*s" $textStart " "
      echo $in
      echo "${head// /=}"
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
