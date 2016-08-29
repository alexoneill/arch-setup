#!/bin/bash
# ui.sh
# aoneill - 07/27/16

# Local directory the script is in
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  # Source the driver
  # Fix an issue with overwriting the secret variable
  # (because it is being sourced twice)
  local backup="$_OTHER_DIR_UTIL"
  source "$DIR/$(basename "$DIR").sh" "$(basename "${BASH_SOURCE[0]}")"
  export _OTHER_DIR_UTIL="$backup"

  function always() {
    DRY_RUN=0 $@
  }

  function show() {
    ! (( QUIET )) && echo "$@"
  }

  function tell() {
    show $@
    ! (( DRY_RUN )) && $@
  }

  function tell_eval() {
    show $@
    ! (( DRY_RUN )) && eval "$@"
  }

  # Global for keeping track of which sections have been shown
  [[ -z "$_UI_SECTION_TITLES" ]] && _UI_SECTION_TITLES="$(temp)"

  function section() {
    in="$@"

    # Skip if the section has already been shown
    [[ -n "$(grep "$in" "$_UI_SECTION_TITLES")" ]] &&
      return
    echo "$in" >> "$_UI_SECTION_TITLES"

    cols=80
    textStart=$((($cols - ${#in}) / 2 - 1))
    head=$(printf "%-${cols}s" "#")

    show "${head// /\#}"
    show -n "$(printf "#%*s" $textStart " ")"
    show -n $in
    show "$(printf "%*s\n" $(($cols - $textStart - ${#in} - 1)) "#")"
    show "${head// /\#}"
  }

  function skipped() {
    in="$@"

    # Continue if the section has not been shown
    [[ -z "$(grep "$in" "$_UI_SECTION_TITLES")" ]] &&
      show "skipped: \`$in'"
  }

  function minor_section() {
    in="$@"

    cols=80
    textStart=$((($cols - ${#in}) / 2))
    head=$(printf "%-${cols}s" " ")

    # Start with a new line
    show

    show "$(printf "%*s" $textStart " ")"
    show $in
    show "${head// /=}"
  }

  function pause() {
    if ! (( QUIET )); then
      show -n "Press ENTER to continue..."
      read ignored
    fi
  }
} 

# Designed for sourcing
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "0" ]] && sourced $@
