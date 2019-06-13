#!/bin/bash

set -e

. /tmp/env.sh

launch() {
    $WORKDIR/qorus/test/docker_test/init.sh
    ./install.sh
    gosu qorus:qorus $WORKDIR/qorus/test/docker_test/launch_qorus.sh
    gosu qorus:qorus oload -Rlv tests/SftpJobModule/*.q*
    #gosu qorus:qorus oload -Rlv tests/SftpWorkflowModule/*.q*
    gosu qorus:qorus qore tests/SftpJobModule/SftpJobModule.qtest -vv
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
