#!/usr/bin/env bash

# common.sh
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

export RESTIC_REPOSITORY="${HOME}/Git/AWS_grocery.backup"
export RESTIC_PASSWORD_FILE="/${HOME}/.restic-pw-aws"

info "Do backup repo"
restic --quiet backup "${HOME}"/Git/AWS_grocery
# restic forget --keep-daily 10 --keep-weekly 4 --keep-monthly 6 --prune