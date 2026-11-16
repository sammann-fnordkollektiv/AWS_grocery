#!/usr/bin/env bash

set -euo pipefail

PORT='15432'
MYPGPASSFILE="$HOME/Git/AWS_grocery/env/.pgpass"
INIT_FILE="etc/_do_init_db.sql"
POPULATE_FILE="backend/app/sqlite_dump_clean.sql"

PGPASSFILE="${MYPGPASSFILE}" \
psql -h 127.0.0.1 -p 15432 -U postgres -d postgres -f "${INIT_FILE}"

PGPASSFILE="${MYPGPASSFILE}" \
psql -h 127.0.0.1 -p 15432 -U grocery_user -d grocerymate_db -f "${POPULATE_FILE}"

