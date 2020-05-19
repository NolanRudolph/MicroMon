#!/bin/bash

while true
do
    DA=$(./test.sh)
    echo $DA | grep -oE "[1-9]+.[1-9]+ usec" | grep -oE "[1-9]+.[1-9]+" > ~/diskAccess.txt
    echo "Updated"
done
