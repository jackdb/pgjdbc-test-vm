#!/bin/sh -e

export DEBIAN_FRONTEND=noninteractive

PROVISIONED_ON=/etc/vm_provision_on_timestamp
if [ -f "$PROVISIONED_ON" ]
then
  echo "VM was already provisioned at: $(cat $PROVISIONED_ON)"
  echo "To run updates manually login via 'vagrant ssh'."
  exit
fi

PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
if [ ! -f "$PG_REPO_APT_SOURCE" ]
then
  # Add PG apt repo:
  echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > "$PG_REPO_APT_SOURCE"

  # Add PGDG repo key:
  wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
fi

# Update package list and upgrade all packages
apt-get update
apt-get -y upgrade

PG_VERSIONS="8.4 9.0 9.1 9.2 9.3"
BOOTSTRAP_DIR="/mnt/bootstrap"
SETUP_DIR="${BOOTSTRAP_DIR}/Vagrant-setup"
SERVER_SSL_DIR="${BOOTSTRAP_DIR}/certdir/server"

# Install PG versions
for PG_VERSION in $PG_VERSIONS
do
  apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"

  PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
  PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
  PG_DIR="/var/lib/postgresql/$PG_VERSION/main/"

  # Edit listen address to '*':
  sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
  sed -i "s/#ssl_ca_file = ''/ssl_ca_file = 'root.crt'/" "$PG_CONF"

  # Update HBA:
  cp "${SETUP_DIR}/pg_hba.conf" "$PG_HBA"

  # SSL Setup:
  cp "${SERVER_SSL_DIR}/root.crt" "$PG_DIR"
  cp "${SERVER_SSL_DIR}/server.crt" "$PG_DIR"
  cp "${SERVER_SSL_DIR}/server.key" "$PG_DIR"

  echo "Setting up test users and databases for $PG_VERSION"
  su - postgres -c "${SETUP_DIR}/pg-setup-${PG_VERSION}.sh"
done

# Restart so that all new config is loaded:
service postgresql restart

# Tag the provision time:
date > "$PROVISIONED_ON"

echo "Successfully setup everything"
