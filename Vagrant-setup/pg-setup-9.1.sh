#!/bin/sh -e

PG_VERSION=9.1

# Source PG_% variables and constants:
. /mnt/bootstrap/Vagrant-setup/pg-variables.sh

# Setup users/databases:
. /mnt/bootstrap/Vagrant-setup/database-setup.sh

# Setup sslinfo:
for db in $DB_LIST
do
  $PSQL -d $db -c 'CREATE EXTENSION sslinfo;'
done
