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

################################################################################
# AWS Login
################################################################################

common_login_aws() {
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  export ACCOUNT=304588611738
  export AWS_PROFILE="AdministratorAccess-${ACCOUNT}"
  export AWS_DEFAULT_REGION="$(aws configure get region --profile "${AWS_PROFILE}")"
  export CDK_DEFAULT_ACCOUNT="${ACCOUNT}"
  export CDK_DEFAULT_REGION="${AWS_DEFAULT_REGION}"
  if aws sts get-caller-identity --profile "${AWS_PROFILE}" >/dev/null 2>&1; then
    nice 'Already logged in'
  else
    fail 'Not logged in. Do it now in opened browser.'
    aws sso login --profile "${AWS_PROFILE}"
  fi
  eval "$(aws configure export-credentials --profile "${AWS_PROFILE}" --format env)"
}


###############################################################################
# AWS Secrets Manager
###############################################################################

common_set_aws_secrets() {
  export SECRET_ID_POSTGRES_URI="aws-grocery-postgres-uri"
  export SECRET_ID_JWT_SECRET_KEY="aws-grocery-jwt-secret"
}

###############################################################################
# Docker environment
###############################################################################

common_set_docker_env () { # 1 path
  DOCKER_ENV="${1}.env"
  export DOCKER_TAG="grocery_app"
  echo "" > "${DOCKER_ENV}"
  echo "AWS_PROFILE=${AWS_PROFILE}" >> "${DOCKER_ENV}"
  echo "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" >> "${DOCKER_ENV}"
  echo "SECRET_ID_POSTGRES_URI=${SECRET_ID_POSTGRES_URI}" >> "${DOCKER_ENV}"
  echo "SECRET_ID_JWT_SECRET_KEY=${SECRET_ID_JWT_SECRET_KEY}" >> "${DOCKER_ENV}"
}

###############################################################################
# CDK environment
###############################################################################

common_set_cdk_env () {
  export CDK_DEFAULT_ACCOUNT="${ACCOUNT}"
  export CDK_DEFAULT_REGION="${AWS_DEFAULT_REGION}"
}

###############################################################################
# AWS ECR environment
###############################################################################

common_set_ecr_env() {
  export REPO_NAME="grocery-app"
  export REPO_URI="${ACCOUNT}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${REPO_NAME}"
}
