#!/usr/bin/env bash

###############################################################################
# Common stuff
###############################################################################

###############################################################################
# Add to respective files:
#
# SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# source "$SCRIPT_DIR/common.sh"
#
###############################################################################

###############################################################################
# Helper functions
###############################################################################

fail() { # 1 = message
  printf "\033[31m[FAIL]: ${1}\033[0m\n"
}

info() { # 1 = message
  printf "\033[34m[INFO]: ${1}\033[0m\n"
}

warn() { # 1 = message
  printf "\033[0;33m[WARN]: ${1}\033[0m\n"
}

nice() { # 1 = message
  printf "\033[32m[NICE]: ${1}\033[0m\n"
}

###############################################################################
# Check correct execution place
###############################################################################

PROJECT_FILE="AWS_grocery.code-workspace"

is_pwd_correct() {
    if [[ -f "${PROJECT_FILE}" ]]; then
        rsync -av ./* ../AWS_Grocery.backup.auto
    else
        error "Go to project folder and re-execute."
        exit 2
    fi
}
