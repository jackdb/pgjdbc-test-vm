#!/usr/bin/env bash
set -euo pipefail

TEST_DB_NAMES=(
    test
    hostdb
    hostssldb
    hostnossldb
    hostsslcertdb
    certdb
)

gen_pg_hba () {
    cat << _EOF_
# IPv4 connections:
host         test           test        0.0.0.0/0     md5
host         hostdb         all         0.0.0.0/0     md5
hostnossl    hostnossldb    all         0.0.0.0/0     md5
hostssl      hostssldb      all         0.0.0.0/0     md5    clientcert=0
hostssl      hostsslcertdb  all         0.0.0.0/0     md5    clientcert=1
hostssl      certdb         all         0.0.0.0/0     cert
_EOF_
}

log () {
    echo "$@" 1>&2
}

psql_super () {
    sudo -u postgres -i -- psql "$@"
}

main () {
    if [[ -f /etc/vm_provisioned_at ]]; then
        log "VM is already provisioned"
        exit 0
    fi

    export DEBIAN_FRONTEND=noninteractive

    # Add PGDG key
    curl -sf https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    # Add PGDG repo
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

    apt-get -y update
    apt-get -y upgrade

    # Dynamically determine all available versions of PostgreSQL to install
    # Will generate a bash array with values: 9.3 9.4 9.5 9.6 10 11 ...
    readarray PG_VERSIONS < <(
        apt-cache search postgresql- |
          awk '/^postgresql-([1-9][0-9]|9\.[0-9]) / { print substr($1, length("postgresql-") + 1) }' |
          sort -n
    )
    # Add our custom certs to a central location
    local PGJDBC_SSL_DIR="/vagrant/certdir/server"

    for pg_version in ${PG_VERSIONS[*]}
    do
        apt-get -y install \
            "postgresql-${pg_version}" \
            "postgresql-contrib-${pg_version}"

        local pg_conf="/etc/postgresql/${pg_version}/main/postgresql.conf"
        local pg_hba="/etc/postgresql/${pg_version}/main/pg_hba.conf"
        local pg_data_dir="/var/lib/${pg_version}/main"

        # Listen on all interfaces (not just localhost)
        echo "listen_addresses = '*'" >> "${pg_conf}"

        # Change port to 10000 + version, i.e. 10095, 10096, 10010, etc
        local pg_port="100$(sed 's/\.//' <<< "${pg_version}")"
        echo "port = ${pg_port}" >> "${pg_conf}"

        local PGJDBC_SSL_DIR="/etc/pgjdbc-ssl"
        if [[ ! -d "${PGJDBC_SSL_DIR}" ]]; then
            mkdir -p "${PGJDBC_SSL_DIR}"
            cp /vagrant/certdir/server/*.* "${PGJDBC_SSL_DIR}"
            chown -R postgres:postgres "${PGJDBC_SSL_DIR}"
            chmod 600 "${PGJDBC_SSL_DIR}"/*.*
        fi

        # Change SSL certs and root CA to point to our common values
        echo "ssl_cert_file = '${PGJDBC_SSL_DIR}/server.crt'" >> "${pg_conf}"
        echo "ssl_key_file = '${PGJDBC_SSL_DIR}/server.key'" >> "${pg_conf}"
        echo "ssl_ca_file = '${PGJDBC_SSL_DIR}/root.crt'" >> "${pg_conf}"

        # Add custom HBA settings to allow inbound connections
        gen_pg_hba >> "${pg_hba}"

        # Restart cluster for changes to take effect
        /etc/init.d/postgresql restart "${pg_version}"

        # Create test user
        psql_super --cluster "${pg_version}/main" -c "CREATE USER test WITH PASSWORD 'test'"
        # Create testing databases
        for db_name in ${TEST_DB_NAMES[*]}
        do
            psql_super --cluster "${pg_version}/main" -c "CREATE DATABASE ${db_name} WITH OWNER test"
            psql_super --cluster "${pg_version}/main" -d "${db_name}" -c "CREATE EXTENSION sslinfo"
            psql_super --cluster "${pg_version}/main" -d "${db_name}" -c "CREATE EXTENSION hstore"
        done

        log "Installed PostgreSQL version ${pg_version} listening on port ${pg_port}"
    done

    # Mark VM as provisioned so we do not rerun next time
    date > /etc/vm_provisioned_at
}

main "$@"
