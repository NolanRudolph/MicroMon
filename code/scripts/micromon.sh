#!/bin/bash

set -x

# End existing Cassandra processes
kill -9 `pidof java`
sleep 1
kill -9 `pidof java`

# Remove data directories
rm -rf ~/vanilla/code/cassandra/data/* ~/micromon/code/cassandra/data/*

# Flush cash
bash ~/micromon/code/scripts/flush.sh

# Begin cassandra
~/micromon/code/cassandra/bin/cassandra

set +x
