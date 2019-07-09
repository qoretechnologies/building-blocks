#!/bin/bash

set -e

. /tmp/env.sh

launch() {
    # setup image
    $WORKDIR/qorus/test/docker_test/init.sh
    ./install.sh
    # run qorus
    gosu qorus:qorus $WORKDIR/qorus/test/docker_test/launch_qorus.sh
    # oload tests
    gosu qorus:qorus oload -Rlv tests/SftpJobModule/*.q*
    #gosu qorus:qorus oload -Rlv tests/SftpWorkflowModule/*.q*
    # run tests
    gosu qorus:qorus qore tests/SftpJobModule/SftpJobModule.qtest -vv
    # turn off qorus
    gosu qorus:qorus $WORKDIR/qorus/test/docker_test/turn_off_qorus.sh
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
