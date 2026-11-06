#!/usr/bin/env bash

docker build \
--file "$(readlink -e backend/Dockerfile)" \
--tag grocerymate-app \
.

