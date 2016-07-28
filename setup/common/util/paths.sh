#!/bin/bash
# paths.sh
# aoneill - 07/26/16

_PATHS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  export BASE="$(cd "$_PATHS_DIR/../../../" && pwd)"

  export COMMON="$(cd "$_PATHS_DIR/../../" && pwd)"
  export PACKAGES="$COMMOM/packages"
  export AIROOTFS="$COMMOM/airootfs"

  export DATA="$BASE/data"

  # Variables for paths to things
  export PASSWD_FILE="$DATA/passwords"
  export HOMEDIR_FILE="$DATA/homedir"
  export WIFI_IFACE_FILE="$DATA/wifi"
}

# Designed for sourcing
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "0" ]] && sourced $@
