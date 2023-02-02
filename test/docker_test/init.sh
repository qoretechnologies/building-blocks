#!/bin/bash

set -e

echo "================================"
echo " Qorus Docker Test initializing"
echo "================================"

. /opt/qorus/bin/env.sh

if [ -z "$QORUS_BUILD_DIR" ]; then
    QORUS_BUILD_DIR=build
fi

# return if systemdb option is set in options file
system_db_is_set() {
    grep -q "^qorus.systemdb" ${OMQ_DIR}/etc/options
}

# return if dbparams file contains omq datasource
dbparams_contains_omq_ds() {
    grep -q "^omq=" ${OMQ_DIR}/etc/dbparams
}

# return if DB type set in OMQ_DB_TYPE env var is valid
db_type_is_valid() {
    echo "${OMQ_DB_TYPE}" | grep -q "\(\(my\|pg\)sql\|oracle\)"
}
# prepare Qorus system DB schema
prepare_schema() {
    echo "Preparing Qorus system schema"
    schema-tool -Vvf
}

parse_db_type_from_db_string() {
    OMQ_DB_TYPE=$(echo "${OMQ_DB_STRING}" | cut -d: -f1)
}

check_db_string_env_var() {
    parse_db_type_from_db_string
    if [ "${OMQ_DB_TYPE}" = "pgsql" ]; then
        OMQ_DB_TABLESPACE=pg_default
    fi
}

check_db_separate_env_vars() {
    if [ -z "${OMQ_DB_NAME}" ]; then
        echo "Error: Missing database name" >&2
        exit 1
    fi
    if [ -z "${OMQ_DB_TYPE}" ]; then
        echo "Error: Missing database type (possible values: mysql, oracle, pgsql)" >&2
        exit 1
    fi
    if ! db_type_is_valid; then
        echo "Error: Invalid database type (possible values: mysql, oracle, pgsql)" >&2
        exit 1
    fi
    if [ -z "${OMQ_DB_USER}" ]; then
        echo "Error: Missing database user" >&2
        exit 1
    fi
    if [ -z "${OMQ_DB_PASS}" ]; then
        echo "Error: Missing database password" >&2
        exit 1
    fi
    if [ -z "${OMQ_DB_HOST}" ]; then
        OMQ_DB_HOST=localhost
    fi
    if [ -z "${OMQ_DB_ENC}" ]; then
        OMQ_DB_ENC=utf8
    fi
    if [ -z "${OMQ_DB_TABLESPACE}" ]; then
        if [ "${OMQ_DB_TYPE}" = "pgsql" ]; then
            OMQ_DB_TABLESPACE=pg_default
        fi
    fi
}

check_db_env_vars() {
    if [ -z "${OMQ_DB_STRING}" ]; then
        check_db_separate_env_vars
    else
        check_db_string_env_var
    fi
}

check_write_db_tablespace() {
    if [ -n "${OMQ_DB_TABLESPACE}" ]; then
        echo "Writing system DB tablespace to options file: ${OMQ_DIR}/etc/options"
        echo "DB tablespace: '${OMQ_DB_TABLESPACE}'"
        echo "qorus-client.omq-data-tablespace: ${OMQ_DB_TABLESPACE}" >>${OMQ_DIR}/etc/options
        echo "qorus-client.omq-index-tablespace: ${OMQ_DB_TABLESPACE}" >>${OMQ_DIR}/etc/options
    fi
}

write_systemdb_option() {
    echo "Writing system DB connection string to options file: ${OMQ_DIR}/etc/options"
    if [ -z "${OMQ_DB_STRING}" ]; then
        systemdb_string="${OMQ_DB_TYPE}:${OMQ_DB_USER}/${OMQ_DB_PASS}@${OMQ_DB_NAME}%${OMQ_DB_HOST}"
    else
        systemdb_string="${OMQ_DB_STRING}"
    fi
    echo "Connection string: '${systemdb_string}'"
    echo "qorus.systemdb: ${systemdb_string}" >>${OMQ_DIR}/etc/options
}

check_load_omquser() {
    # check variables for omquser datasource
    if [ -n "${OMQUSER_DB_NAME}" -a -n "${OMQUSER_DB_TYPE}" -a -n "${OMQUSER_DB_USER}" -a -n "${OMQUSER_DB_PASS}" ]; then
        if [ -z "${OMQUSER_DB_HOST}" ]; then
            OMQUSER_DB_HOST=localhost
        fi

        omquser_string="${OMQUSER_DB_TYPE}:${OMQUSER_DB_USER}/${OMQUSER_DB_PASS}@${OMQUSER_DB_NAME}%${OMQUSER_DB_HOST}"

    elif [ -n "${OMQUSER_DB_STRING}" ]; then
        omquser_string="${OMQUSER_DB_STRING}"

    else
        # use same DB like system
        if [ -z "${OMQ_DB_STRING}" ]; then
            omquser_string="${OMQ_DB_TYPE}:${OMQ_DB_USER}/${OMQ_DB_PASS}@${OMQ_DB_NAME}%${OMQ_DB_HOST}"
        else
            omquser_string="${OMQ_DB_STRING}"
        fi
    fi

    echo "Creating omquser DB connection: '${omquser_string}'"
    qdp db{datasource=${systemdb_string}}/connections create name=omquser,description=omquser,url=db://${omquser_string},enabled=1,connection_type=DATASOURCE
}

do_env_var_config() {
    echo "Checking environment variables for system DB configuration"

    check_db_env_vars
    check_write_db_tablespace
    write_systemdb_option
}

db_config() {
    echo "Configuring Qorus system DB"

    if system_db_is_set; then
        echo "System DB already configured in options file"
    else
        echo "Warning: systemdb option is not set"

        if [ ! -e ${OMQ_DIR}/etc/dbparams ]; then
            echo "Warning: dbparams file is missing"
            do_env_var_config
        elif ! dbparams_contains_omq_ds; then
            echo "Warning: dbparams file does not contain omq datasource"
            do_env_var_config
        else
            echo "System DB configured in dbparams file"
        fi
    fi
}

do_init_steps() {
    # configure database connection
    db_config

    # prepare DB schema
    prepare_schema

    # load the omquser datasource; must happen before tests are loaded
    check_load_omquser
}

do_init_steps

echo "================================="
echo " Qorus Docker Test init complete"
echo "================================="
echo
