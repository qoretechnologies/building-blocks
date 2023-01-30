#!/bin/bash
set -x
set -e

. /tmp/env.sh

# setup QORUS_SRC_DIR env var
cwd=`pwd`
if [ -z "${QORUS_SRC_DIR}" ]; then
    if [ -d "$cwd/qlib-qorus" ] || [ -e "$cwd/bin/qctl" ] || [ -e "$cwd/cmake/QorusMacros.cmake" ] || [ -e "$cwd/lib/qorus.ql" ]; then
        QORUS_SRC_DIR=$cwd
    else
        QORUS_SRC_DIR=$WORKDIR/qorus
    fi
fi
export QORUS_SRC_DIR

launch() {
    ${QORUS_SRC_DIR}/test/docker_test/launch_qorus_k8s.sh
}

case "$1" in
    "bash")
        exec "$@"
    ;;
    "sh")
        exec "$@"
    ;;
    "")
        launch
    ;;
    *)
        launch
    ;;
esac
