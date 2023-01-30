#!/bin/bash

set -x
set -e

. /opt/qorus/bin/env.sh

# setup environment to run tests in k8s on the qorus-core node
export TEST_BLACKLIST="QorusBug2400|QorusDebugTest|qdsp|qwf|SchemaSnapshotsStress|Issue3530Workflow|BuildingBlocksCommon"
export QORUS_SKIP_LOCAL_TESTS=1
export QORUS_SRC_DIR=/opt/qorus/user

# DEBUG
if [ ! -f /opt/qorus/user/test/qorus-tests.qrf ]; then
    echo MISSING TESTS!
    ls -l /opt/qorus/user.test
    tail -f /dev/null
fi

# load tests
if [ "${SKIP_LOAD_TESTS:-0}" = "0" ]; then
    oload /opt/qorus/user/test/qorus-tests.qrf -lvR
fi

# disable stateless test services not designed to be tested under k8s
qrest put services/stateless-ftp-test/disable
qrest put services/stateless-rest-test/disable
qrest put services/stateless-service-test/disable
qrest put services/stateless-soap-test/disable
qrest put services/stateless-websocket-test/disable

# enable HTTP debugging when running on bee
if [ "${RUNNER_HOST}" = "bee" ]; then
    qrest put system/listeners/qorus-1/setLogOptions option=-1
fi

# set tmpdir for tests
qrest put system/props/regression-test?action=set key=tmpdir,args=/opt/qorus/user/test
qrest put remote/user/fs-regression url=file:///opt/qorus/user/test

# run tests
set +e
/opt/qorus/user/test/run_tests.sh
TEST_STATUS=$?
echo $TEST_STATUS > /opt/qorus/user/test/TEST_STATUS
set -e

# fix environment
export QORUS_SRC_DIR=/opt/qorus
