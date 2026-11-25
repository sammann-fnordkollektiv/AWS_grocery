#!/usr/bin/env python3

"""
This is a wrapper for running app on AWS infrastructure.
It gets the passwords from AWS Secrets Manager, adds them to the environment
and runs the original run.py.

Naming convention in environment is "SECRET_ID_{KEY_IN_SECRETS_MANAGER}",
example:

* Key in AWS Secrets Manager: "SECRET_ID_POSTGRES_URI"
* Value of SECRET_ID_POSTGRES_URI in running environment: AWS Secrets Manager, Seceret name
* Key inside the JSON secret: "POSTGRES_URI"

"""

import json
import os
import sys

import boto3
from botocore.exceptions import BotoCoreError, ClientError

# Naming convention in environment: SECRET_ID_X. X = key in AWS Secrets Manager
ENVIRONEMT_KEYS = ["SECRET_ID_POSTGRES_URI", "SECRET_ID_JWT_SECRET_KEY"]

# Exit codes
EXIT_ON_SECRETS_MANAGER_FAILURE = 1
EXIT_ON_NO_SECRET_STRING_FOUND = 2
EXIT_ON_KEY_EMPTY_OR_NOT_STRING = 3
EXIT_ON_NO_VALID_JSON_OR_FIELD = 4


def main():
    region = get_region()
    for environment_key in ENVIRONEMT_KEYS:
        secrets_to_get = os.getenv(environment_key)
        response = get_response_or_exit(secrets_to_get, region)
        secret_string = get_secret_string_or_exit(response)
        key = environment_key.replace("SECRET_ID_", "")
        secret = get_secret_or_exit(secret_string, key)
        os.environ[key] = secret
    run_py = os.path.join(os.path.dirname(os.path.abspath(__file__)), "run.py")
    os.execv(sys.executable, [sys.executable, run_py, *sys.argv[1:]])


def get_response_or_exit(secret: str, region: str) -> dict:
    region = get_region()
    try:
        client = boto3.client("secretsmanager", region_name=region)
        return client.get_secret_value(SecretId=secret)
    except (BotoCoreError, ClientError) as error:
        # Keine Secret-Werte in die Fehlermeldung schreiben.
        print(
            f"[FAIL] Getting AWS Secrets Manager {secret} raises ({type(error).__name__}).",
            file=sys.stderr,
        )
        sys.exit(EXIT_ON_SECRETS_MANAGER_FAILURE)


def get_region() -> str:
    getenv_region = "REGION"
    region = os.getenv(getenv_region)
    if not region:
        raise RuntimeError(f"[FAIL] Environment {getenv_region} missing.")


def get_secret_string_or_exit(response: dict) -> str:
    secret_string = response.get("SecretString")
    if not secret_string:
        print("[FAIL] No 'SecretString' found.\n", file=sys.stderr)
        sys.exit(EXIT_ON_NO_SECRET_STRING_FOUND)
    return secret_string


def get_secret_or_exit(secret_string: str, key: str) -> str:
    try:
        secret = json.loads(secret_string)[key]
        if isinstance(secret, str) and secret:
            return secret
        else:
            print(f"[FAIL] {key} is either not str or empty.", file=sys.stderr)
            sys.exit(EXIT_ON_KEY_EMPTY_OR_NOT_STRING)
    except (json.JSONDecodeError, KeyError, TypeError):
        print(
            f"[FAIL] Secret not in valid JSON format and/or not including field '{key}'.\n",
            file=sys.stderr,
        )
        sys.exit(EXIT_ON_NO_VALID_JSON_OR_FIELD)


if __name__ == "__main__":
    main()
