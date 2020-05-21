#!/bin/bash

set -ex

# End Cassandra process
kill -9 `pidof java`
sleep 1
kill -9 `pidof java`

# Remove data directories
rm -rf ~/ssd/vanilla/code/cassandra/data/* ~/ssd/micromon/code/cassandra/data/*

# Flush cash
bash ~/ssd/vanilla/code/scripts/flush.sh

# Begin cassandra
~/ssd/vanilla/code/cassandra/bin/cassandra

set +ex
