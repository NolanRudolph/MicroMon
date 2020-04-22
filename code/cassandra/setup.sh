#!/bin/bash

# Kill any previous Cassandra processes
kill -9 `pidof java`

# Run build.xml with preconfigured objectives
sudo cp -r ./.m2 /root/
sudo ant;

echo "Setup Completed.";
