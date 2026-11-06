#!/usr/bin/env bash
HOST="${1}"
ssh -i ~/.ssh/msit.pem ec2-user@"${HOST}"
