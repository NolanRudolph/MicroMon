#!/bin/bash
set -x

export CODE=$PWD
export YCSBHOME=$CODE/mapkeeper/ycsb/YCSB
export CSRC=$CODE/cassandra

export HOST=192.168.1.1
export PORT=9042

set +x
