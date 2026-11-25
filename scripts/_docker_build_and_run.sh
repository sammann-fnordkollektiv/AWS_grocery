#!/usr/bin/env bash

# common.sh
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

info "Do build Docker"
docker build \
--build-arg APP_UID="$(id -u)" \
--build-arg APP_GID="$(id -g)" \
--file backend/Dockerfile \
--tag "${DOCKER_TAG}" .
if [ $? == 0 ]; then
    info "Do run docker"
    warn "--rm \ remove container afterwards"
    warn "--volume "$HOME/.aws:/home/appuser/.aws:ro" \ readonly my personal"
    warn "AWS and -SSO account into Docker. In production replace this with"
    warn "EKS or IAM role (masterschool.com provides me none)"
    docker run \
    --rm \
    --volume "$HOME/.aws:/home/appuser/.aws:ro" \
    --env-file backend/.env \
    "${DOCKER_TAG}"
    if [ $? -ne 0 ]; then
        fail "docker not ran"
    fi
else
    fail "docker not built"
fi
