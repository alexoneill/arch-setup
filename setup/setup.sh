#!/bin/bash
# setup.sh
# aoneill - 07/27/16

# Don't overwrite a previously set DIR
if [[ "$DIR" != "" ]]; then
  _OTHER_DIR_SETUP="$DIR"
fi

# Location of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function init() {
  SETUP="$DIR"
  source "$SETUP/common/util/util.sh"

  # Make sure data exists
  ! [[ -d "$DATA" ]] && mkdir -p "$DATA"

  # Run the requested package
  [[ "$#" -gt "0" ]] && run_stage $@
}

function sourced() {
  SETUP="$DIR"
  source "$SETUP/common/util/util.sh" "all"

  export SETUP_PREP="prep"
  export SETUP_PACK="packages"
  export SETUP_POST="post-install"

  [[ "$#" -gt "0" ]] && source_stage $@

  export DIR="$_OTHER_DIR_SETUP"
}

# Run init only when run
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "1" ]] && init $@
[[ "$EXEC" == "0" ]] && sourced $@
