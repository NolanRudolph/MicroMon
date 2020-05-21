#!/bin/bash

# PREREQUISITES
# 1. Be sure to mount the proper HDD/SSD onto your home directory
# 2. You MUST be in the FullDynamic branch, "git checkout FullDynamic"
# 3. Run this script from the ~/butterflyeffect directory

# Program should quit when error occurs, and allows telegrammed commands
set -xe

## INSTALL REQUIRED SOFTWARE ##

#<<WgetError
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk maven ant

# Switch to compatible JDK version
printf "\n*** IT IS OKAY TO RECEIVE \"error: no alternatives\" ERROR ***\n"
printf "\n*** IF YOU RECEIVE \"directory does not exist: /usr/lib/jvm/java-1.8.0-openjdk-amd64\", READ COMMENTS IN THIS SCRIPT ***\n"
# Hey, sorry that happened. This is most likely due to the architecture of the machine you're using.
# Go ahead and run "$ ls /usr/lib/jvm" and note the file that's prefixed with "java-1.8.0-openjdk-"
# In the below line, adjust "amd64" to the system type that proceeds "java-1.8.0-openjdk-" 
# (e.g. arm64)
# Then rerun this script :)
sudo update-java-alternatives -s java-1.8.0-openjdk-amd64
java -version # This should output " openjdk version "1.8.0_252" "


## SETTING UP EDITED CASSANDRA ##

# Create a required directory
sudo mkdir /root/.m2
sudo mkdir /root/.m2/repository
sudo chown -R $USER /root/.m2

# Compile the source code
cd code/cassandra
bash setup.sh


## SETTING UP VANILLA ##

# This will be placed in home directory
cd ~

set +ex
