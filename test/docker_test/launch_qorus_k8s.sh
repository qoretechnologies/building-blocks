#!/bin/bash

set -e
set -x

# get CPU architecture
arch=`uname -m`

export IMAGE_TAG=qorus-test-`echo $CI_COMMIT_BRANCH-$CI_PIPELINE_ID | sed 's,/,-,g'`-$arch
export IMAGE_TAG_GO=qorus-test-`echo $CI_COMMIT_BRANCH-$CI_PIPELINE_ID | sed 's,/,-,g'`-go-$arch

# turn on core dumps
ulimit -c unlimited

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

# check for final branches
export FINAL_BRANCH=`${QORUS_SRC_DIR}/test/docker_test/final_branch.sh`

if [ "$USE_LOCAL_AWS" != "1" ]; then
    # setup AWS access
    if [ -n "`grep ID=alpine /etc/os-release`" ]; then
        # install the AWS CLI on Alpine
        apk add --no-cache python3 py3-pip
        pip3 install --upgrade pip
        pip3 install awscli
        rm -rf /var/cache/apk/*
    elif [ ! -d /opt/qorus/bin/aws ]; then
        # install the AWS CLI on standard linux
        mkdir /opt/qorus/bin/aws
        cd /opt/qorus/bin/aws
        if [ "$arch" = "aarch64" ]; then
            curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
        else
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        fi
        unzip awscliv2.zip >/dev/null
        ./aws/install
        rm -rf aws
        cd -
    fi
fi

if [ "$USE_LOCAL_K8S" = "1" ]; then
    echo using local k8s
else
    . ${QORUS_SRC_DIR}/test/docker_test/postgres_lib.sh

    # start docker daemon if necessary
    if [ ! -S /var/run/docker.sock ]; then
        dockerd &
        sleep 1
    fi

    # install and setup kind and kubectl
    # install KinD
    if [ "$arch" = "aarch64" ]; then
        curl -sL https://github.com/kubernetes-sigs/kind/releases/download/v0.12.0/kind-linux-arm64 -o /usr/local/bin/kind
    else
        curl -sL https://github.com/kubernetes-sigs/kind/releases/download/v0.12.0/kind-linux-amd64 -o /usr/local/bin/kind
    fi
    chmod a+x /usr/local/bin/kind

    # install kubectl
    if [ "$arch" = "aarch64" ]; then
        curl -sL https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/arm64/kubectl -o /usr/local/bin/kubectl
    else
        curl -sL https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
    fi
    chmod a+x /usr/local/bin/kubectl

    # create registry container unless it already exists
    reg_name='kind-registry'
    reg_port='5000'
    docker inspect -f '{{.State.Running}}' "${reg_name}" || true
    running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || printf false)"
    if [ "${running}" != 'true' ]; then
        start_postgres

        # start registry
        docker run \
            -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
            registry:2
        # create cluster
        cat <<EOF | kind create cluster --name=qorus-test --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:${reg_port}"]
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /qorus
    containerPath: /opt/qorus
- role: worker
  extraMounts:
  - hostPath: /qorus
    containerPath: /opt/qorus
EOF

        # connect the registry to the cluster network
        # (the network may already be connected)
        docker network connect "kind" "${reg_name}" || true
    else
        setup_postgres_on_rippy

        # delete cluster in advance
        kind delete cluster --name qorus-test || true

        # create cluster
        cat <<EOF | kind create cluster --name=qorus-test --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:${reg_port}"]
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /qorus
    containerPath: /opt/qorus
- role: worker
  extraMounts:
  - hostPath: /qorus
    containerPath: /opt/qorus
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 6443
EOF
    fi

    # Document the local registry
    # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
fi

kubectl cluster-info

# create shared qorus dirs
for dir in etc etc.default init test log; do
    if [ -d /qorus/$dir ]; then
        rm -rf /qorus/$dir
    fi
done
rm -rf /qorus/user/*
mkdir -p /qorus/etc /qorus/init /qorus/user/test /qorus/log

# copy tests to shared qorus dir
cp -apr ${QORUS_SRC_DIR}/test/* /qorus/user/test/

# copy docker test scripts to user/test
cp ${QORUS_SRC_DIR}/test/docker_test/*sh /qorus/user/test/

# setup $OMQ_DIR for tests
mkdir -p /qorus/user/jar
cp ${QORUS_SRC_DIR}/test/svc-test/qorus-svc-test.jar /qorus/user/jar/
mkdir -p /qorus/user/modules/
cp ${QORUS_SRC_DIR}/test/dev-modules/TestJob.qm /qorus/user/modules/
cp ${QORUS_SRC_DIR}/test/dev-modules/TestService.qm /qorus/user/modules/
cp ${QORUS_SRC_DIR}/test/dev-modules/TestWorkflow2.qm /qorus/user/modules/
cp ${QORUS_SRC_DIR}/test/dev-modules/TestWorkflow.qm /qorus/user/modules/
cp ${QORUS_SRC_DIR}/test/dev-modules/MultiInterface.qm /qorus/user/modules/
cp ${QORUS_SRC_DIR}/test/dev-modules/TestUserConnectionProvider.qm /qorus/user/modules/

# set options before start
if [ "`grep ^qorus.rbac-security /qorus/etc/options | wc -l`" = "0" ]; then
    echo qorus.rbac-security: true >> /qorus/etc/options
fi
# enable test execution
if [ "`grep ^qorus-client.allow-test-execution /qorus/etc/options | wc -l`" = "0" ]; then
    echo qorus-client.allow-test-execution: true >> /qorus/etc/options
fi
# turn on debugging for exception traces
if [ "`grep ^qorus.debug-system /qorus/etc/options | wc -l`" = "0" ]; then
    echo qorus.debug-system: true >> /qorus/etc/options
fi
if [ "`grep ^qorus.debug-qorus-internals /qorus/etc/options | wc -l`" = "0" ]; then
    echo qorus.debug-qorus-internals: true >> /qorus/etc/options
fi
# add test user connection provider module
if [ "`grep ^qorus.connection-modules.*TestUserConnectionProvider.qm /qorus/etc/options | wc -l`" = "0" ]; then
    echo "qorus.connection-modules: /opt/qorus/user/test/dev-modules/TestUserConnectionProvider.qm" >> /qorus/etc/options
fi
# add overcommit option
if [ "`grep ^qorus.allow-node-overcommit-percent /qorus/etc/options | wc -l`" = "0" ]; then
    echo "qorus.allow-node-overcommit-percent: 10" >> /qorus/etc/options
fi

# enable the creator API in debugging builds
if [ "${BUILD_PRODUCTION_IMAGE}" != "1" -a "${FINAL_BRANCH}" != "1" -a "`grep ^qorus.unsupported-creator-api /qorus/etc/options`" = 0 ]; then
    echo "qorus.unsupported-creator-api: true" >> ${OMQ_DIR}/etc/options
fi

# change owner to qorus:qorus in images
if [ -f /qorus/init/QORUS_UID ]; then
    QORUS_UID=`cat /qorus/init/QORUS_UID`
else
    QORUS_UID=999
fi
if [ -f /qorus/init/QORUS_GID ]; then
    QORUS_GID=`cat /qorus/init/QORUS_GID`
else
    QORUS_GID=999
fi
chown ${QORUS_UID}:${QORUS_GID} /qorus -R

if [ "$USE_LOCAL_IMAGE" = "1" ]; then
    echo using local image: ${IMAGE_TAG}
elif [ -n "$USE_S3_IMAGE" ]; then
    # retrieving qorus image from S3: $USE_S3_IMAGE
    echo retrieving image from s3://qorus-test-images/${USE_S3_IMAGE}
    aws s3 cp s3://qorus-test-images/${USE_S3_IMAGE} .
    docker import ${USE_S3_IMAGE} ${IMAGE_TAG}
else
    # build image in docker
    echo building qorus image in docker
    sed -i 's/^.git$//' .dockerignore || true
    if [ -n "${QORUS_SRC_DIR}" ]; then
        cd ${QORUS_SRC_DIR}
    fi

    if [ "${BUILD_PRODUCTION_IMAGE}" = "1" -o "${FINAL_BRANCH}" = "1" ]; then
        # disable multiarch for now
        export BUILD_SINGLE_ARCH=1
        if [ "${BUILD_SINGLE_ARCH}" = "1" ]; then
            docker buildx uninstall 2> /dev/null || true
            docker build -t ${IMAGE_TAG} -f ubuntu.dockerfile .
            # tag and push image to registry
            docker tag ${IMAGE_TAG} localhost:5000/${IMAGE_TAG} && docker push localhost:5000/${IMAGE_TAG}
        else
            #docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
            docker buildx install
            docker buildx create --use --driver docker-container
            docker buildx inspect --bootstrap
            #docker buildx build --platform linux/amd64 --tag $IMAGE_TAG -f ./ubuntu.dockerfile . --load
            #docker tag ${IMAGE_TAG} localhost:5000/${IMAGE_TAG} && docker push localhost:5000/${IMAGE_TAG}
            docker buildx build --platform linux/arm64,linux/amd64 --tag $IMAGE_TAG -f ./ubuntu.dockerfile . --push
        fi
    else
        docker build -t ${IMAGE_TAG} -f ubuntu-debug.dockerfile .
        # tag and push image to registry
        docker tag ${IMAGE_TAG} localhost:5000/${IMAGE_TAG} && docker push localhost:5000/${IMAGE_TAG}
    fi
    if [ -n "${QORUS_SRC_DIR}" ]; then
        cd -
    fi
fi

IMAGE_NAME=$IMAGE_TAG
IMAGE_TAG_REGEX=localhost:5000/$IMAGE_TAG

if [ "$USE_LOCAL_DB" = "1" ]; then
    echo using local db
fi

# prepare qorus config files for k8s
cp ${QORUS_SRC_DIR}/test/k8s/*yaml /opt/qorus/bin
sed -i \
    -e "s,__IMAGE_TAG__,$IMAGE_TAG_REGEX,g" \
    -e "s/__DB_TYPE__/$OMQ_DB_TYPE/g" \
    -e "s/__DB_USER__/$OMQ_DB_USER/g" \
    -e "s/__DB_PASS__/$OMQ_DB_PASS/g" \
    -e "s/__DB_NAME__/$OMQ_DB_NAME/g" \
    -e "s/__DB_HOST__/$OMQ_DB_HOST/g" \
    /opt/qorus/bin/*.yaml

# substitute qorus host path for local testing if applicable
if [ -n "${USE_QORUS_HOST_PATH}" ]; then
    sed -i "s,path: \"/opt/qorus\",path: \"${USE_QORUS_HOST_PATH}\"," /opt/qorus/bin/qorus-core-pod.yaml /opt/qorus/bin/qorus-statefulset.yaml
fi

# apply config
kubectl apply -f /opt/qorus/bin/qorus-service.yaml
kubectl apply -f /opt/qorus/bin/qorus-roles.yaml
if [ "`kubectl get statefulset qorus --no-headers | wc -l`" = "0" ]; then
    kubectl apply -f ${QORUS_STATEFULSET:-/opt/qorus/bin/qorus-statefulset.yaml}
fi
if [ "`kubectl get pod qorus-core --no-headers | wc -l`" = "0" ]; then
    kubectl apply -f ${QORUS_CORE_POD:-/opt/qorus/bin/qorus-core-pod.yaml}
fi

# show config
kubectl get pods

if [ ! -d ${QORUS_SRC_DIR}/log ]; then
    mkdir ${QORUS_SRC_DIR}/log
fi

# wait until qorus pods are up - can take > 3 minutes
set +x
waited=0
printf "waiting for qorus pods to start: "
while true; do
    if [ -z "$ip_done" ]; then
        count=`kubectl get pods | grep qorus-core.*Running | wc -l`
        if [ $count -eq 1 ]; then
            ip_done=1
            echo "qorus-core pod started"
            printf "waiting for qorus-0 pod to start: "
        elif [ $waited -eq 60 ]; then
            kubectl describe pod qorus-core
        fi
    fi
    count=`kubectl get pods | grep Running | wc -l`
    if [ $count -eq 2 ]; then
        echo started
        break
    fi
    # DEBUG
    #kubectl get pods
    #kubectl logs qorus-0 -c qorus-init

    # 5 minute time limit
    if [ $waited -eq 300 ]; then
        kubectl get pods | tee ${QORUS_SRC_DIR}/log/get-pods.log
        kubectl logs pod/qorus-0 -c qorus-init || true | tee ${QORUS_SRC_DIR}/log/qorus-0-pod-qorus-init-log.log
        kubectl describe pod qorus-0 || true | tee ${QORUS_SRC_DIR}/log/qorus-0-pod-qorus-init.log
        kubectl describe pod qorus-core || true | tee ${QORUS_SRC_DIR}/log/qorus-core-pod.log
        echo && echo "Waited too long for Qorus pods to start; aborting build."
        kind delete cluster --name qorus-test || true
        cleanup_postgres_on_rippy
        exit 1
    fi
    printf .
    # sleep for 1 second
    sleep 1
    waited=$((waited+1))
done

# now wait until the Qorus HTTP server is up
waited=0
printf "waiting for qorus to start: "
while true; do
    if [[ $(kubectl exec qorus-core -- /opt/qorus/user/test/remote_exec.sh qrest system/instance-key 2> /dev/null) ]]; then
        echo Qorus is up
        break
    fi

    # 2 minute time limit
    if [ $waited -eq 120 ]; then
        kubectl get pods | tee ${QORUS_SRC_DIR}/log/get-pods.log
        kubectl logs pod/qorus-0 -c qorus-init || true | tee ${QORUS_SRC_DIR}/log/qorus-0-pod-qorus-init-log.log
        kubectl describe pod qorus-0 || true | tee ${QORUS_SRC_DIR}/log/qorus-0-pod-qorus-init.log
        kubectl describe pod qorus-core || true | tee ${QORUS_SRC_DIR}/log/qorus-core-pod.log
        kubectl logs qorus-core || true | tee ${QORUS_SRC_DIR}/log/qorus-core-logs.log
        # copy logs to target dir to use as artifacts (in case there are any)
        cp -apRxuv /qorus/log/* ${QORUS_SRC_DIR}/log/
        echo && echo "Waited too long for Qorus to start; aborting build."
        kind delete cluster --name qorus-test || true
        cleanup_postgres_on_rippy
        exit 1
    fi
    printf .
    # sleep for 1 second
    sleep 1
    waited=$((waited+1))
done
set -x

# delete test status flag before running tests, if it exists
rm -f /qorus/user/test/TEST_STATUS

# load and run tests
if [ "${SKIP_TESTS}" = "1" ]; then
    echo "skipping tests (SKIP_TESTS=1)"
else
    if [ "${SKIP_LOAD_TESTS:-0}" = "0" ]; then
        kubectl exec qorus-core -- su qorus -c /opt/qorus/user/test/run_k8s.sh
    else
        kubectl exec qorus-core -- su qorus -c "SKIP_LOAD_TESTS=1 /opt/qorus/user/test/run_k8s.sh"
    fi
fi

# delete cluster after execution is done
kind delete cluster --name qorus-test || true

set +x
# copy logs to target dir to use as artifacts
cp -apRxuv /qorus/log/* ${QORUS_SRC_DIR}/log

# make sure there were no asserts
if grep ASSERT ${QORUS_SRC_DIR}/log/*log; then
    echo ASSERTs found, CI failed
    false
else
    echo no ASSERTs found, CI OK
fi
set -x

TEST_STATUS=`cat /qorus/user/test/TEST_STATUS`
if [ "${TEST_STATUS}" != "0" ]; then
    echo tests failed
    cleanup_postgres_on_rippy
    false
fi

if [ "$USE_LOCAL_IMAGE" = "1" ]; then
    echo "using local image; not writing to S3"
elif [ "$USE_S3_IMAGE" = "1" ]; then
    echo "skipping pushing image to AWS S3 (USE_S3_IMAGE=1)"
elif [ "$FINAL_BRANCH" != "1" ]; then
    echo "skipping pushing image to AWS S3 (branch $CI_COMMIT_BRANCH)"
elif [ "$MANUAL_IMAGE" = "1" ]; then
    echo "skipping pushing image to AWS S3 (MANUAL_IMAGE=1)"
else
    # get unique file name
    target_name=${IMAGE_TAG}.tar

    # make tar of docker image
    docker save $IMAGE_NAME -o $target_name
    ls -l qorus-test*

    if [ -n "${SFTPSTORAGE_PKEY}" -a -n "${SFTPSTORAGE_HOST}" -a -n "${SFTPSTORAGE_HOSTKEY}" ]; then
        if [ ! -d ~/.ssh ]; then mkdir -m 0700 -p ~/.ssh; fi
        echo "${SFTPSTORAGE_HOSTKEY}" >> ~/.ssh/known_hosts
        export KEYFILE=/opt/qorus/bin/sftpstorage-ssh-key
        echo "${SFTPSTORAGE_PKEY}" > ${KEYFILE}
        chmod 600 ${KEYFILE}
        # copy production image to local SFTP storage
        scp -i ${KEYFILE} $target_name ${SFTPSTORAGE_USER:-sftpstorage}@${SFTPSTORAGE_HOST}:qorus-test-images/$target_name
    else
        # copy production image to S3
        aws s3 cp $target_name s3://qorus-test-images/$target_name
    fi

    # make GO image
    if [ "$arch" = "aarch64" ]; then
        (
            cat <<EOF
FROM ${IMAGE_TAG} as qorus_base
ARG DEBIAN_FRONTEND=noninteractive

# install grpcurl (NOTE: "go get" requires git for grpcurl)
RUN apt update && apt install -y git wget openssl ca-certificates --no-install-recommends
RUN wget https://golang.org/dl/go1.17.2.linux-arm64.tar.gz --no-check-certificate -O /opt/qorus/bin/golang.tar.gz
RUN tar -C /usr/local -xzf /opt/qorus/bin/golang.tar.gz
RUN rm /opt/qorus/bin/golang.tar.gz
RUN ln -s /usr/local/go/bin/go /usr/local/bin
RUN openssl s_client -showcerts -connect proxy.golang.org:443 </dev/null 2>/dev/null|openssl x509 -outform PEM >  ${cert_location}/proxy.golang.crt
RUN go get github.com/fullstorydev/grpcurl@latest
RUN go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

RUN apt remove -y wget && apt autoremove -y
EOF
        ) > /opt/qorus/bin/dockerfile
    else
        (
            cat <<EOF
FROM ${IMAGE_TAG} as qorus_base
ARG DEBIAN_FRONTEND=noninteractive

# install grpcurl (NOTE: "go get" requires git for grpcurl)
RUN apt update && apt install -y git wget openssl ca-certificates --no-install-recommends
RUN wget https://golang.org/dl/go1.17.2.linux-amd64.tar.gz --no-check-certificate -O /opt/qorus/bin/golang.tar.gz
RUN tar -C /usr/local -xzf /opt/qorus/bin/golang.tar.gz
RUN rm /opt/qorus/bin/golang.tar.gz
RUN ln -s /usr/local/go/bin/go /usr/local/bin
RUN openssl s_client -showcerts -connect proxy.golang.org:443 </dev/null 2>/dev/null|openssl x509 -outform PEM >  ${cert_location}/proxy.golang.crt
RUN go get github.com/fullstorydev/grpcurl@latest
RUN go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

RUN apt remove -y wget && apt autoremove -y
EOF
        ) > /opt/qorus/bin/dockerfile
    fi
    docker build -t ${IMAGE_TAG_GO} -f /opt/qorus/bin/dockerfile .

    # get unique file name
    target_name_go=${IMAGE_TAG_GO}.tar

    # make tar of docker image
    docker save $IMAGE_TAG_GO -o $target_name_go
    ls -l qorus-test*

    if [ -n "${SFTPSTORAGE_PKEY}" -a -n "${SFTPSTORAGE_HOST}" -a "${SFTPSTORAGE_HOSTKEY}" ]; then
        if [ ! -d ~/.ssh ]; then mkdir -m 0700 -p ~/.ssh; fi
        echo "${SFTPSTORAGE_HOSTKEY}" >> ~/.ssh/known_hosts
        export KEYFILE=/opt/qorus/bin/sftpstorage-ssh-key
        echo "${SFTPSTORAGE_PKEY}" > ${KEYFILE}
        chmod 600 ${KEYFILE}
        # copy production image to local SFTP storage
        scp -i ${KEYFILE} $target_name_go ${SFTPSTORAGE_USER:-sftpstorage}@${SFTPSTORAGE_HOST}:qorus-test-images/$target_name_go
    else
        # copy production image to S3
        aws s3 cp $target_name_go s3://qorus-test-images/$target_name_go
    fi
fi

cleanup_postgres_on_rippy
