#!/bin/bash
set -x

#Pass the release name
export OS_RELEASE_NAME=$1
export PARA="-j40"
export CODE=$PWD
export YCSBHOME=$CODE/mapkeeper/ycsb/YCSB
export CODE=$CODE
export SSD=$HOME/ssd
export SSD_DEVICE="/dev/sdc"
export SSD_PARTITION="/dev/sdc1"
export USER=$USER
export DATASRC=""
export CSRC=$CODE/cassandra

export HOST=192.168.1.1
export PORT=9042

#Add other servers in the cluster with comma separation
SERVERS=192.168.1.1,192.168.1.2,192.168.1.3

set +x
