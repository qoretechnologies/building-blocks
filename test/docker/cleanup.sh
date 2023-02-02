#!/bin/sh

set -e
set -x

. /opt/qorus/bin/env.sh

# source postgres lib
. ./test/docker_test/postgres_lib.sh

# cleanup DB
cleanup_postgres_on_rippy
