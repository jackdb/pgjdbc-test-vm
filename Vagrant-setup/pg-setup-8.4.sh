#!/bin/sh -e

PG_VERSION=8.4

# Source PG_% variables and constants:
. /mnt/bootstrap/Vagrant-setup/pg-variables.sh

# Setup users/databases:
. /mnt/bootstrap/Vagrant-setup/database-setup.sh

# Setup sslinfo:
cd /usr/share/postgresql/$PG_VERSION/contrib/
for db in $DB_LIST
do
  $PSQL -d $db -f sslinfo.sql
done
