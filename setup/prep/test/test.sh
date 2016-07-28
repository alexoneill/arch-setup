#!/bin/bash
# prep.sh
# aoneill - 07/26/16

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(cd ../../../ && pwd)"
SETUP="$(cd ../../ && pwd)"

source "$SETUP/common/util/util.sh"

function init() {
  for file in $(find "$DIR" -maxdepth 1 -type f -name "*-*" | sort); do
    [[ -x "$file" ]] && "$file"
  done
}

# Run init only when run
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "1" ]] && init $@
