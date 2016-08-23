#!/bin/bash
# paths.sh
# aoneill - 07/26/16

# Local directory the script is in
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  export BASE="$(cd "$DIR/../../../" && pwd)"

  export COMMON="$(cd "$DIR/../" && pwd)"
  export PACKAGES="$COMMON/packages"
  export AIROOTFS="$COMMON/airootfs"

  export DATA="$BASE/data"

  # Variables for paths to things
  export PASSWD_FILE="$DATA/passwords"
  export HOMEDIR_FILE="$DATA/homedir"
}

# Designed for sourcing
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "0" ]] && sourced $@
