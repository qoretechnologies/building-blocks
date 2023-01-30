#!/bin/bash

set -e
set -x

. /opt/qorus/bin/env.sh

# turn on core dumps
ulimit -c unlimited

# start Qorus
qorus --log-level=ALL --debug-system
