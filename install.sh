#!/bin/bash

usage()
{
    echo "usage: install.sh [-h]"
}

while [ "$1" != "" ]; do
    case $1 in
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

# check $OMQ_DIR
if [ ! -d "$OMQ_DIR" ]; then
    echo '$OMQ_DIR is not set, exiting....'
    exit 1
fi

MODULE_DIR="$OMQ_DIR/user/modules"
# copy modules into correct folder
# check folder
if [ ! -d "${MODULE_DIR}" ]; then
    echo '$MODULE_DIR is not set, exiting....'
    exit 1
fi

# check module file
MODULES='BuildingBlocksCommon.qm SftpWorkflowModule SftpJobModule'
for MODULE in $MODULES; do
    MODULE_PATH=$(dirname $0)/${MODULE}
    if [ ! -e "${MODULE_PATH}" ]; then
        echo "${MODULE_PATH} not found, exiting...."
        exit 1
    fi

    # copy module
    if ! cp -rf ${MODULE_PATH} ${MODULE_DIR}; then
        echo "error copying ${MODULE_PATH} into ${MODULE_DIR}, exiting...."
        exit 1
    fi

    echo "${MODULE} installed"
done

# restart qorus ?
