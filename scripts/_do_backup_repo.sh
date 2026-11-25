#!/usr/bin/env bash

# common.sh
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

info "do backup repo"
rsync -a ./* ../AWS_Grocery.backup.auto

