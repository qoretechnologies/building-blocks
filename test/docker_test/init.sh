#!/bin/bash

set -e

echo "================================"
echo " Qorus Docker Test initializing"
echo "================================"

. /opt/qorus/bin/env.sh

if [ -z "$QORUS_BUILD_DIR" ]; then
    QORUS_BUILD_DIR=build
fi

# prepare Qorus system DB schema
prepare_schema() {
    echo "Preparing Qorus system schema"
    schema-tool -Vvf
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
