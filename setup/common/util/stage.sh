#!/bin/bash
# stage.sh
# aoneill - 07/27/16

_STAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function sourced() {
  function run_stage() {
    driver="$1"
    shift 1
    "$SETUP/$driver/$driver.sh" $@
  }

  function source_stage() {
    driver="$1"
    shift 1
    source "$SETUP/$driver/$driver.sh" $@
  }
} 

# Designed for sourcing
EXEC=$(test "${BASH_SOURCE[0]}" != "${0}"; echo $?)
[[ "$EXEC" == "0" ]] && sourced $@
