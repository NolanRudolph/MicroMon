#!/bin/bash

kill -9 `pidof java`
rm -rf ~/butterflyeffect/code/cassandra/data/*
kill -9 `pidof java`
