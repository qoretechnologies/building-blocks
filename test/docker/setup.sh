#!/bin/sh

set -e
set -x

. /opt/qorus/bin/env.sh

start_postgres() {
    docker run --name=postgres --network=host -e POSTGRES_PASSWORD=omq -e TZ=Europe/Prague -e PGTZ=Europe/Prague -d postgres:15
    docker ps
    # wait for PostgreSQL server to start
    printf "waiting on PostgreSQL server: "
    waited=0
    while true; do
        ver=`qore -ne 'try { printf("%s", (new Datasource("pgsql:postgres/omq@postgres%localhost:5432")).getServerVersion()); } catch () { echo "ERROR: $@"; }'`
        if [ -n "$ver" ]; then
            echo ": started server version $ver"
            break
        fi

        # 30 second time limit
        if [ $waited -eq 30 ]; then
            echo && echo "Waited too long for PostgreSQL to start; aborting build."
            exit 1
        fi
        printf .
        # sleep for 1 second
        sleep 1
        waited=$((waited+1))
    done

    export OMQ_DB_USER=postgres
    export OMQ_DB_PASS=omq
    export OMQ_DB_NAME=postgres
    export OMQ_DB_HOST=`qore -ne 'printf("%s", (map $1.address, get_netif_list(), $1.family == AF_INET && $1.address !~ /^127/ && $1.address !~ /\.0$/)[0]);'`
    export OMQ_SYSTEMDB=pgsql:${OMQ_DB_USER}/${OMQ_DB_PASS}@${OMQ_DB_NAME}%${OMQ_DB_HOST}

    # make sure we can access the DB
    qore -nX "(new Datasource(\"${OMQ_SYSTEMDB}\")).getServerVersion()"
}

setup_postgres_on_rippy() {
    # add env vars to environment file and load it
    # NOTE: must convert to lower case only, or the psql commands below will fail
    user=omq_test_`qore -lUtil -ne 'printf("%s", get_random_string(10));' | tr A-Z a-z`
    echo export OMQ_DB_USER=${user} >> /opt/qorus/bin/env.sh
    echo export OMQ_DB_PASS=omq >> /opt/qorus/bin/env.sh
    echo export OMQ_DB_NAME=${user} >> /opt/qorus/bin/env.sh
    echo export OMQ_DB_HOST=${RUNNER_HOST:=rippy} >> /opt/qorus/bin/env.sh
    systemdb=pgsql:${user}/omq@${user}%${RUNNER_HOST:=rippy}
    echo export OMQ_SYSTEMDB=${systemdb} >> /opt/qorus/bin/env.sh

    . /opt/qorus/bin/env.sh

    # create user for test
    cat <<EOF | psql -Upostgres
create database ${OMQ_DB_NAME} encoding = 'utf8';
\connect ${OMQ_DB_NAME};
create user ${OMQ_DB_USER} password 'omq';
grant create, connect, temp on database ${OMQ_DB_NAME} to ${OMQ_DB_USER};
grant create on tablespace omq_data to ${OMQ_DB_USER};
grant create on tablespace omq_index to ${OMQ_DB_USER};
grant select on all tables in schema pg_catalog to ${OMQ_DB_USER};
EOF
    echo created pgsql user ${OMQ_DB_USER} and db ${OMQ_DB_NAME}

    # make sure we can access the DB
    qore -nX "(new Datasource(\"${OMQ_SYSTEMDB}\")).getServerVersion()"

    export POSTGRES_RIPPY=1
}

cleanup_postgres_on_rippy() {
    if [ "${POSTGRES_RIPPY}" = "1" ]; then
        # drop postgresql test user
        cat <<EOF | psql -Upostgres
drop owned by ${OMQ_DB_USER};
drop database ${OMQ_DB_NAME} with (force);
drop role ${OMQ_DB_USER};
EOF
        echo dropped pgsql user ${OMQ_DB_USER}
    fi
}

# start postgres and setup up env vars
if [ -n "$DOCKER_NETWORK" ]; then
    setup_postgres_on_rippy
else
    start_postgres
fi

# setup Kafka
echo --- downloading Kafka
cd /opt
wget https://downloads.apache.org/kafka/3.3.1/kafka_2.13-3.3.1.tgz
echo --- installing Kafka
tar xvf kafka_2.13-3.3.1.tgz
cd kafka_2.13-3.3.1
echo --- starting Kafka
./bin/zookeeper-server-start.sh config/zookeeper.properties &
./bin/kafka-server-start.sh config/server.properties &
sleep 2
echo --- creating the test topic
bin/kafka-topics.sh --create --topic quickstart-events --bootstrap-server localhost:9092
