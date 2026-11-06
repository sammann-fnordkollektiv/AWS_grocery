#!/usr/bin/env bash

docker run \
--interactive \
--tty \
--publish 5000:5000 \
--restart on-failure:5 \
grocerymate-app

