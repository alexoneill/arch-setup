#!/bin/bash
# util.sh
# aoneill - 07/26/16

# Don't overwrite a previously set DIR
if [[ "$DIR" != "" ]]; then
  _OTHER_DIR_UTIL="$DIR"
fi

# Location of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  passed="$1"
  function gate() {
    if [[ "$passed" == "all" ]]; then
      cat -
    else
      cat - | grep -v "$passed\$"
    fi
  }

  # Source the support
  if [[ "$passed" != "" ]]; then
    for file in $(find "$DIR" -maxdepth 1 -type f -not -name "util.sh" \
                    | gate | sort); do
      [[ -x "$file" ]] && source "$file"
    done
  fi

  export DIR="$_OTHER_DIR_UTIL"
}

# Run `init' only when exec'd, run `sourced' only when sourced
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "1" ]] && init $@
[[ "$EXEC" == "0" ]] && sourced $@
