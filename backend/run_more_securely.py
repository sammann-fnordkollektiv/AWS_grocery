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
from pathlib import Path
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError, ParamValidationError

# Naming convention in environment: SECRET_ID_X. X = key in AWS Secrets Manager
ENVIRONMENT_KEYS = ["SECRET_ID_POSTGRES_URI", "SECRET_ID_JWT_SECRET_KEY"]

# Exit codes
EXIT_ON_SECRETS_ENVIRONMENT_FAILURE = 1
EXIT_ON_PARAMVALIDATIONERROR = 2
EXIT_ON_SECRETS_MANAGER_FAILURE = 3
EXIT_ON_READ_ONLY_CACHE_FAILURE = 4
EXIT_ON_NO_SECRET_STRING_FOUND = 5
EXIT_ON_KEY_EMPTY_OR_NOT_STRING = 6
EXIT_ON_NO_VALID_JSON_OR_FIELD = 7
EXIT_ON_RUN_PY_NOT_FOUND = 8


def main() -> None:
    region = get_region()
    client = boto3.client("secretsmanager", region_name=region)
    for environment_key in ENVIRONMENT_KEYS:
        secret_id = get_secret_id(environment_key)
        response = get_response_or_exit(client, secret_id)
        secret_string = get_secret_string_or_exit(response)
        key = environment_key.replace("SECRET_ID_", "")
        secret = get_secret_or_exit(secret_string, key)
        os.environ[key] = secret
    run_py = Path(__file__).resolve().with_name("run.py")
    if not run_py.is_file():
        fail(f"Application entry point not found: {run_py}", EXIT_ON_RUN_PY_NOT_FOUND)
    os.execv(sys.executable, [sys.executable, str(run_py), *sys.argv[1:]])


def get_region() -> str:
    getenv_region = "AWS_DEFAULT_REGION"
    region = os.getenv(getenv_region)
    if not region:
        raise RuntimeError(f"[FAIL] Environment {getenv_region} missing.")
    return region


def get_secret_id(environment_key: str) -> str:
    secret_id = os.getenv(environment_key)
    if not secret_id:
        fail(
            f"Required environment variable {environment_key} is missing.",
            EXIT_ON_SECRETS_ENVIRONMENT_FAILURE,
        )
    return secret_id


def fail(message: str, exit_code: int) -> None:
    print(f"[FAIL] {message}\n", file=sys.stderr)
    raise SystemExit(exit_code)


def get_response_or_exit(client: Any, secret: str) -> dict[str, Any]:
    try:
        return client.get_secret_value(SecretId=secret)
    except ParamValidationError as error:
        fail(
            f"Invalid parameter for Secrets Manager: {error}",
            EXIT_ON_PARAMVALIDATIONERROR,
        )
    except (BotoCoreError, ClientError) as error:
        fail(
            f"Getting AWS Secrets Manager {secret} raises ({type(error).__name__}).",
            EXIT_ON_SECRETS_MANAGER_FAILURE,
        )
    except OSError as error:
        fail(
            f"If '[Errno 30] Read-only file system', execute 'direnv allow'. Else good luck! {error}",
            EXIT_ON_READ_ONLY_CACHE_FAILURE,
        )


def get_secret_string_or_exit(response: dict[str, Any]) -> str:
    secret_string = response.get("SecretString")
    if not isinstance(secret_string, str) or not secret_string:
        fail("No 'SecretString' found.", EXIT_ON_NO_SECRET_STRING_FOUND)
    return secret_string


def get_secret_or_exit(secret_string: str, key: str) -> str:
    try:
        secret = json.loads(secret_string)[key]
        if isinstance(secret, str) and secret:
            return secret
        else:
            fail(f"{key} is either not str or empty.", EXIT_ON_KEY_EMPTY_OR_NOT_STRING)
    except (json.JSONDecodeError, KeyError, TypeError):
        fail(
            f"Secret not in valid JSON format and/or not including field '{key}'.",
            EXIT_ON_NO_VALID_JSON_OR_FIELD,
        )


if __name__ == "__main__":
    main()
