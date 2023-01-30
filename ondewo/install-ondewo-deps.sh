#!/bin/bash

# install ONDEWO components on Linux

set -x
set -e

PIP=pip

# install go
if [ -f /etc/os-release ]; then
    if [ -n "`grep Ubuntu /etc/os-release`" ]; then
        sudo apt update && sudo apt install -y golang git --no-install-recommends
    elif [ -n "`grep -i redhat /etc/os-release | head -1`" ]; then
        sudo dnf update && sudo dnf install -y golang git
    else
        # if we are in Alpine, then we assume we are root
        apk update && apk add --no-cache go git
    fi
elif [ "`uname -s`" = "Darwin" ]; then
    sudo port install go
    PIP=pip3
else
    echo "unknown Operating System; exiting"
    exit 1
fi

# installing gprc components
go get github.com/fullstorydev/grpcurl/...
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# install ONDEWO BPI dependencies
REQ_FILE=/opt/qorus/bin/ondewo-requirements.txt

cat <<EOF > ${REQ_FILE}
# The only requirements are included in the ondewo-nlu-client-python and ondewo-logging submodules, make sure they are properly installed.
grpcio
grpcio_reflection
protobuf==3.13.0
python-dotenv
ondewo-logging>=2.0.0
ondewo-nlu-client==2.0.*
ondewo-vtsi-client
EOF

if [ -n "$OMQ_DIR" ]; then
    ${PIP} install --prefix=$OMQ_DIR/user/python -r ${REQ_FILE}
fi
    ${PIP} install -r ${REQ_FILE}
endif
rm ${REQ_FILE}


