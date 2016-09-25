#!/bin/bash
# prep.sh
# aoneill - 07/26/16

# Don't overwrite a previously set DIR
if [[ "$DIR" != "" ]]; then
  _OTHER_DIR_PREP="$DIR"
fi

# Don't overwrite a previously set SECTION
if [[ "$DIR" != "" ]]; then
  _OTHER_SECTION_PREP="$SECTION"
fi

# Location of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function init() {
  for file in $(find "$DIR" -maxdepth 1 -type f -name "*.setup" | sort); do
    [[ -x "$file" ]] && "$file"
  done
}

function sourced() {
  SETUP="$(cd "$DIR/../" && pwd)"
  source "$SETUP/common/util/util.sh" "all"

  passed="$1"
  function gate() {
    if [[ "$passed" == "all" ]]; then
      cat -
    else
      cat - | grep -v "$passed\$"
    fi
  }

  if [[ "$passed" != "" ]]; then
    for file in $(find "$DIR" -maxdepth 1 -type f -name "*.setup" \
                    | gate | sort); do

      [[ -x "$file" ]] && source "$file"
    done
  fi

  export DIR="$_OTHER_DIR_PREP"
  export SECTION="$_OTHER_SECTION_PREP"
}

# Run `init' only when exec'd, run `sourced' only when sourced
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "1" ]] && init $@
[[ "$EXEC" == "0" ]] && sourced $@
