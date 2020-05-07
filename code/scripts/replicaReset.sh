#!/bin/bash

kill -9 `pidof java`
rm -rf ~/butterflyeffect/code/cassandra/data/*
sleep 1
kill -9 `pidof java`
