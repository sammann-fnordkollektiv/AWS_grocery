#!/usr/bin/env bash

docker build --file "$(readlink -e backend/Dockerfile)" --tag grocerymate-app .
docker run --interactive --tty --publish 5000:5000 grocerymate-app

