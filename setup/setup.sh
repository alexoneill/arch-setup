#!/bin/bash
# setup.sh
# aoneill - 07/27/16

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SETUP="$DIR"
source "$SETUP/common/util/util.sh"

function init() {
  # Make sure data exists
  ! [[ -d "$DATA" ]] && mkdir -p "$DATA"

  # Run the requested package
  [[ "$#" -gt "0" ]] && run_stage $@
}

function run() {
  driver="$1"
  shift 1
  "$DIR/$driver/$driver.sh" $@
}

function sourced() {
  export SETUP_PREP="prep"
  export SETUP_PACK="packages"
  export SETUP_POST="post-install"

  [[ "$#" -gt "0" ]] && source_stage $@
}

# Run init only when run
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "1" ]] && init $@
[[ "$EXEC" == "0" ]] && sourced $@
