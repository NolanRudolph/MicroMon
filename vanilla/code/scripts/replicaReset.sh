#!/bin/bash

set -x

kill -9 `pidof java`
rm -rf $CODE/cassandra/data/*
sleep 1
kill -9 `pidof java`
sleep 3
$CODE/cassandra/bin/cassandra

set -x
