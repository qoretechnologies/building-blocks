#!/bin/sh

set -e
set -x

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
