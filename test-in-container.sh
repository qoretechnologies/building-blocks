apt-get update
apt-get install git-all -y

git clone https://github.com/qoretechnologies/building-blocks.git
cd building-blocks

export OMQ_DB_NAME: postgres
export OMQ_DB_TYPE: pgsql
export OMQ_DB_HOST: postgres
export OMQ_DB_USER: postgres
export OMQ_DB_PASS: omq
export WORKDIR: /opt/qorus
export QORUS_SRC_DIR: .
