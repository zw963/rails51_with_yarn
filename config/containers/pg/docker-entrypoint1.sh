#!/bin/bash

set -e

pgbouncer /config/pgbouncer.ini -d
/docker-entrypoint.sh "$@"
