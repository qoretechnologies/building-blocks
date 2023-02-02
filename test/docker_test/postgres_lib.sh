#!/bin/sh

start_postgres() {
    docker run --name=postgres --network=host -e POSTGRES_PASSWORD=omq -e TZ=Europe/Prague -e PGTZ=Europe/Prague -d postgres:15

    # wait for PostgreSQL server to start
    printf "waiting on PostgreSQL server: "
    waited=0
    while true; do
        ver=$(qore -ne 'try { printf("%s", (new Datasource("pgsql:postgres/omq@postgres%localhost:5432")).getServerVersion()); } catch () {}')
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
        waited=$((waited + 1))
    done

    export OMQ_DB_USER=postgres
    export OMQ_DB_PASS=omq
    export OMQ_DB_NAME=postgres
    export OMQ_DB_HOST=$(qore -ne 'printf("%s", (map $1.address, get_netif_list(), $1.family == AF_INET && $1.address !~ /^127/ && $1.address !~ /\.0$/)[0]);')
    export OMQ_SYSTEMDB=pgsql:${OMQ_DB_USER}/${OMQ_DB_PASS}@${OMQ_DB_NAME}%${OMQ_DB_HOST}

    # make sure we can access the DB
    qore -nX "(new Datasource(\"${OMQ_SYSTEMDB}\")).getServerVersion()"
}

start_postgres
