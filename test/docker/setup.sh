#!/bin/bash

set -e
set -x

. /opt/qorus/bin/env.sh

wait_for_postgres() {
    # wait for PostgreSQL server to start
    printf "waiting on PostgreSQL server: "
    waited=0
    while true; do
        ver=$(qore -l Util -ne 'try { printf("%s", (new Datasource("pgsql:postgres/omq@postgres%localhost:5432")).selectRow("select version()").version); } catch (hash<ExceptionInfo> ex) { printf("%s\n", get_exception_string(ex)); }')
        if [ -n "$ver" ]; then
            echo ": started server version $ver"
            break
        fi

        # 30 second time limit
        if [ $waited -eq 30 ]; then
            echo && echo "Waited too long to connect with PostgreSQL; aborting build."
            exit 1
        fi
        printf .
        # sleep for 1 second
        sleep 1
        waited=$((waited + 1))
    done

    export OMQ_SYSTEMDB=pgsql:${OMQ_DB_USER}/${OMQ_DB_PASS}@${OMQ_DB_NAME}%${OMQ_DB_HOST}

    # make sure we can access the DB
    qore -nX "(new Datasource(\"${OMQ_SYSTEMDB}\")).getServerVersion()"
}

wait_for_postgres

# enable test execution
echo qorus-client.allow-test-execution: true >> /opt/qorus/etc/options

. /opt/qorus/bin/init.sh
qctl start

# setup Kafka
echo --- downloading Kafka
cd /opt
wget https://downloads.apache.org/kafka/3.3.2/kafka_2.12-3.3.2.tgz
echo --- installing Kafka
tar xvf kafka_2.12-3.3.2.tgz
cd kafka_2.12-3.3.2
echo --- starting Kafka
./bin/zookeeper-server-start.sh config/zookeeper.properties &
./bin/kafka-server-start.sh config/server.properties &
sleep 2
echo --- creating the test topic
bin/kafka-topics.sh --create --topic quickstart-events --bootstrap-server localhost:9092
