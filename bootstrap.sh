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
host         test           test_super  0.0.0.0/0     md5
host         hostdb         all         0.0.0.0/0     md5
hostnossl    hostnossldb    all         0.0.0.0/0     md5
_EOF_
}


gen_pg_hba_ssl () {
    cat << _EOF_
# Mandatory SSL:
hostssl      hostssldb      all         0.0.0.0/0     md5    clientcert=0
hostssl      hostsslcertdb  all         0.0.0.0/0     md5    clientcert=1
hostssl      certdb         all         0.0.0.0/0     cert
_EOF_
}

gen_pg_hba_scram () {
    cat << _EOF_
# SCRAM:
host         test_scram     test_scram  0.0.0.0/0     scram-sha-256
_EOF_
}

log () {
    echo "$@" 1>&2
}

psql_super () {
    sudo -u postgres -i -- psql "$@"
}

get_pg_versions () {
    apt-cache search postgresql- |
      awk '/^postgresql-([1-9][0-9]|9\.[0-9]) / { print substr($1, length("postgresql-") + 1) }' |
      sort -n
}

is_pg_version_at_least () {
    local pg_version="${1}"
    local min_version="${2}"
    return "$(
        awk \
          -v "version="${pg_version} \
          -v "min_version=${min_version}" \
          'BEGIN { print !(version >= min_version) }'
        )"
}

wait_for_postgres () {
    local pg_version="${1}"
    for i in {1..60}
    do
        if pg_isready --cluster "${pg_version}/main"; then
            break
        fi
        log "Waiting for PostgreSQL server version ${pg_version} to start"
        sleep 1
    done
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
    local pg_versions
    readarray pg_versions < <(get_pg_versions)

    # First install latest client so that we have things like pg_isready
    apt-get -y install postgresql-client-${pg_versions[-1]}

    # Add our custom certs to a central location
    local PGJDBC_SSL_DIR="/vagrant/certdir/server"

    for pg_version in ${pg_versions[*]}
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

        # Add custom HBA settings to allow inbound connections
        gen_pg_hba >> "${pg_hba}"

        # Change SSL certs and root CA to point to our common values
        if is_pg_version_at_least "${pg_version}" "9.3" ; then
            # Add SSL settings to postgresql.conf
            echo "ssl_cert_file = '${PGJDBC_SSL_DIR}/server.crt'" >> "${pg_conf}"
            echo "ssl_key_file = '${PGJDBC_SSL_DIR}/server.key'" >> "${pg_conf}"
            echo "ssl_ca_file = '${PGJDBC_SSL_DIR}/root.crt'" >> "${pg_conf}"
            # Add SSL entries to HBA
            gen_pg_hba_ssl >> "${pg_hba}"
        fi

        if is_pg_version_at_least "${pg_version}" "10" ; then
            # Add SCRAM entries to HBA
            gen_pg_hba_scram >> "${pg_hba}"
        fi

        # Restart cluster for changes to take effect
        /etc/init.d/postgresql restart "${pg_version}"
        # Wait for the server to actual start
        wait_for_postgres "${pg_version}"

        # Create test user
        psql_super --cluster "${pg_version}/main" -c "CREATE USER test WITH PASSWORD 'test'"
        psql_super --cluster "${pg_version}/main" -c "CREATE USER test_super WITH SUPERUSER PASSWORD 'test'"
        # Create testing databases
        for db_name in ${TEST_DB_NAMES[*]}
        do
            psql_super --cluster "${pg_version}/main" -c "CREATE DATABASE ${db_name} WITH OWNER test"
            if is_pg_version_at_least "${pg_version}" "9.1" ; then
                psql_super --cluster "${pg_version}/main" -d "${db_name}" -c "CREATE EXTENSION sslinfo"
                psql_super --cluster "${pg_version}/main" -d "${db_name}" -c "CREATE EXTENSION hstore"
            fi
        done

        if is_pg_version_at_least "${pg_version}" "10" ; then
            # Create SCRAM users
            psql_super --cluster "${pg_version}/main" \
                -c "SET password_encryption = 'scram-sha-256'" \
                -c "CREATE USER test_scram WITH PASSWORD 'test'" \
                -c "CREATE DATABASE test_scram WITH OWNER test_scram"
            psql_super --cluster "${pg_version}/main" \
                -d "test_scram" \
                -c "CREATE EXTENSION sslinfo" \
                -c "CREATE EXTENSION hstore"
        fi

        log "Installed PostgreSQL version ${pg_version} listening on port ${pg_port}"
    done

    # Mark VM as provisioned so we do not rerun next time
    date > /etc/vm_provisioned_at

    log "Installation completed successfully."
}

main "$@"
