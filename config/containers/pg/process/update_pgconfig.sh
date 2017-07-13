#!/bin/bash

set -e

# sed -i "\$ahost    replication     dbreplication   0.0.0.0/32      md5" $PGDATA/pg_hba.conf
sed -i "\$ainclude_if_exists = '/config/pg_master.conf'" $PGDATA/postgresql.conf
