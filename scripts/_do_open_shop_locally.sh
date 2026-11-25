#!/usr/bin/env bash

# common.sh
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

info "Open shop locally"
firefox http://127.0.0.1:5000