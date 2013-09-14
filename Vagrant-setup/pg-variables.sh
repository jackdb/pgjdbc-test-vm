# PG variables and constants (sourced by pg-setup-[PG_VERSION].sh files)
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
PG_DIR="/var/lib/postgresql/$PG_VERSION/main/"
PG_PORT=$(grep "port = " "$PG_CONF" | awk '{ print $3 }')
PSQL="psql -p $PG_PORT"
DB_LIST="test hostdb hostssldb hostnossldb hostsslcertdb certdb"
