#!/bin/bash

set -ex

# End Cassandra process
kill -9 `pidof java`
sleep 1
kill -9 `pidof java`

# Remove data directories
rm -rf ~/vanilla/code/cassandra/data/* ~/micromon/code/cassandra/data/*

# Flush cash
bash ~/vanilla/code/scripts/flush.sh

# Begin cassandra
~/vanilla/code/cassandra/bin/cassandra

set +ex
