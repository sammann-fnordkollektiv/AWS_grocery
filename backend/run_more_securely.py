#!/usr/bin/env python3

"""
This is a wrapper for running app on AWS infrastructure.
It gets the passwords from AWS Secrets Manager, adds them to the environment
and runs the original run.py.

Naming convention in environment is "SECRET_ID_{KEY_IN_SECRETS_MANAGER}",
example:

* Key in AWS Secrets Manager: "SECRET_ID_POSTGRES_URI"
* Value of SECRET_ID_POSTGRES_URI in running environment: AWS Secrets Manager,
  Secret name
* Key inside the JSON secret: "POSTGRES_URI"

FIXME TODO a) the docker app uses POSTGRES_URI from the environment to access
the database:
* Running the app locally: Set up database and create POSTGRES_URI.
* Running the app in ec2 with db there: Set up database an create POSTGRES_URI.
* Running the app in AWS: Then this script's environment contains a json data
  variable called "DB_SECRET". And the POSTGRES_URI is created from there.
What s left to do is, to somehow use the same POSTGRES_URI creating process for
the above two environments.
"""

import json
import os
import sys
from pathlib import Path
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError, ParamValidationError

ENVIRONMENT_KEYS = ["SECRET_ID_JWT_SECRET_KEY"]


def main() -> None:
    postgres_uri = get_postgres_uri()
    os.environ["POSTGRES_URI"] = postgres_uri

    client = boto3.client("secretsmanager", region_name=get_region_name())
    for environment_key in ENVIRONMENT_KEYS:
        key, secret = get_key_and_secret(client, environment_key)
        os.environ[key] = secret

    run_py = Path(__file__).resolve().with_name("run.py")
    if not run_py.is_file():
        fail(
            f"Application entry point not found: {run_py}",
            "FAIL_REASON_RUN_PY_NOT_FOUND",
        )
    os.execv(sys.executable, [sys.executable, str(run_py), *sys.argv[1:]])


def get_region_name() -> str:
    getenv_region = "AWS_DEFAULT_REGION"
    region_name = os.getenv(getenv_region)
    if not region_name:
        fail(
            f"[FAIL] Environment {getenv_region} missing.", "FAIL_REASON_REGION_MISSING"
        )
    return region_name


def get_key_and_secret(client: Any, environment_key: str) -> tuple[str, str]:
    secret_id = get_secret_id(environment_key)
    response = get_response(client, secret_id)
    secret_string = get_secret_string(response)
    key = environment_key.replace("SECRET_ID_", "")
    return key, get_secret(secret_string, key)


def get_secret_id(environment_key: str) -> str:
    secret_id = os.getenv(environment_key)
    if not secret_id:
        fail(
            f"Required environment variable {environment_key} is missing.",
            "FAIL_REASON_SECRETS_ENVIRONMENT_FAILURE",
        )
    return secret_id


def fail(message: str, fail_reason: str) -> None:
    print(f"[FAIL] {message}\n", file=sys.stderr)
    raise RuntimeError(fail_reason)


def get_response(client: Any, secret: str) -> dict[str, Any]:
    try:
        return client.get_secret_value(SecretId=secret)
    except ParamValidationError as error:
        fail(
            f"Invalid parameter for Secrets Manager: {error}",
            "FAIL_REASON_PARAMVALIDATIONERROR",
        )
    except (BotoCoreError, ClientError) as error:
        fail(
            f"Getting AWS Secrets Manager {secret} raises ({type(error).__name__}).",
            "FAIL_REASON_SECRETS_MANAGER_FAILURE",
        )
    except OSError as error:
        fail(
            f"If '[Errno 30] Read-only file system', execute 'direnv allow'. Else good luck! {error}",
            "FAIL_REASON_READ_ONLY_CACHE_FAILURE",
        )


def get_secret_string(response: dict[str, Any]) -> str:
    secret_string = response.get("SecretString")
    if not isinstance(secret_string, str) or not secret_string:
        fail("No 'SecretString' found.", "FAIL_REASON_NO_SECRET_STRING_FOUND")
    return secret_string


def get_secret(secret_string: str, key: str) -> str:
    try:
        secret = json.loads(secret_string)[key]
        if isinstance(secret, str) and secret:
            return secret
        else:
            fail(
                f"{key} is either not str or empty.",
                "FAIL_REASON_KEY_EMPTY_OR_NOT_STRING",
            )
    except (json.JSONDecodeError, KeyError, TypeError):
        fail(
            f"Secret not in valid JSON format and/or not including field '{key}'.",
            "FAIL_REASON_NO_VALID_JSON_OR_FIELD",
        )


def get_postgres_uri() -> str:
    postgres_uri = None
    if "DB_SECRET" in os.environ:  # environment startet in AWS
        s = json.loads(os.environ["DB_SECRET"])
        postgres_uri = f"postgresql://{s['username']}:{s['password']}@{s['host']}:{s.get('port', 5432)}/{s.get('dbname', 'grocerymate_db')}"
    else:  # environment startet locally (not AWS)
        postgres_uri = os.environ.get("POSTGRES_URI")

    if not postgres_uri:
        fail(
            "POSTGRES_URI could not be determined.", "FAIL_REASON_MISSING_POSTGRES_URI"
        )
    else:
        return postgres_uri


if __name__ == "__main__":
    main()
