#!/bin/bash

# PREREQUISITES
# 1. Be sure to mount the proper HDD/SSD onto your home directory
# 2. You MUST be in the FullDynamic branch, "git checkout FullDynamic"

# Program should quit when error occurs, and allows telegrammed commands
set -xe

# Home directory install
cd ~

# Install Required Software
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk python-pip
sudo update-java-alternatives -s java-1.8.0-openjdk-amd64
# Switch to compatible JDK version
printf "\n*** IT IS OKAY TO RECEIVE \"error: no alternatives\" ERROR ***\n"
printf "\n*** IF YOU RECEIVE \"directory does not exist: /usr/lib/jvm/java-1.8.0-openjdk-amd64\", READ COMMENTS IN THIS SCRIPT ***\n"
# If failed, it is most likely due to the architecture of the machine you're using.
# Go ahead and run "ls /usr/lib/jvm" and note the file that's prefixed with "java-1.8.0-openjdk-"
# In the below line, adjust "amd64" to the system type that proceeds "java-1.8.0-openjdk-"
# (e.g. arm64)
# Then rerun this script

echo "This should return \"openjdk version \"1.8.0_252\"\""
java -version # This should output " openjdk version "1.8.0_252" "
pip install cqlsh

echo "*** THIS HAS A CHANCE OF FAILING, IF IT DOES SEE COMMENTS IN THIS SCRIPT ***"
# Please go to: https://fossies.org/linux/misc/apache-cassandra-3.11.6-src.tar.gz/
# Then press the link at the top, "Contents of <link>" and download to your local computer
# Use "$ scp path/to/downloads/apache-cassandra-3.11.6-src.tar.gz <cloudlab node>:~"
# Then restart the script
wget https://fossies.org/linux/misc/apache-cassandra-3.11.6-src.tar.gz
tar -xzf apache-cassandra-3.11.6-src.tar.gz

sudo update-java-alternatives -s java-1.8.0-openjdk-amd64
java -version # This should output " openjdk version "1.8.0_252" "

# We need this python lib
rm -rf .local/lib/python2.7/site-packages/cqlshlib
mv apache-cassandra-3.11.6-src/pylib/cqlshlib ~/.local/lib/python2.7/site-packages
rm -rf apache-cassandra-3.11.6-src.tar.gz apache-cassandra-3.11.6-src

# Make sure we're using the correct butterflyeffect branch
cd butterflyeffect/code
git checkout FullDynamic
source scripts/setvars.sh

set +x
echo "You can now run tests using \"bash scripts/customTest.sh\". Make sure you change variable HOST in ~/butterflyeffect/code/scripts/setvars.sh to the IP of the server node for the Cassandra benchmark. Then run \"source ~/butterflyeffect/code/scripts/setvars.sh\" again."

set +e
