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

# Get the source code
echo "*** THIS HAS A CHANCE OF FAILING, IF IT DOES SEE COMMENTS IN THIS SCRIPT ***"
# Hey, sorry it failed. 
# Please go to: https://fossies.org/linux/misc/apache-cassandra-3.11.6-src.tar.gz/
# Then press the link at the top, "Contents of <link>" and download to your local computer
# Then use "$ scp path/to/downloads/apache-cassandra-3.11.6-src.tar.gz <cloudlab node>:~"
# Uncomment lines 12 and 56 and restart this script :)

wget https://fossies.org/linux/misc/apache-cassandra-3.11.6-src.tar.gz
#WgetError

cd ~
tar -xzf apache-cassandra-3.11.6-src.tar.gz
rm -f apache-cassandra-3.11.6-src.tar.gz
mv apache-cassandra-3.11.6-src cassandra

# Create a structure similar to butterflyeffect
mkdir vanilla
mkdir vanilla/code
mv cassandra vanilla/code

# Copy configuration files to vanilla Cassandra
CODE=~/butterflyeffect/code
cp -r $CODE/mapkeeper vanilla/code
cp $CODE/cassandra/conf/cassandra.yaml vanilla/code/cassandra/conf
sed -i "s/butterflyeffect/vanilla/g" vanilla/code/cassandra/conf/cassandra.yaml
cp $CODE/cassandra/conf/cassandra-topology.properties vanilla/code/cassandra/conf
cp $CODE/cassandra/setup.sh vanilla/code/cassandra

# Compile source code
cd vanilla/code/cassandra
bash setup.sh

set +x

printf "\n\n*** ONE LAST STEP ***\n"
echo "On line 615 and 692 of ~/vanilla/code/cassandra/conf/cassandra.yaml and ~/butterflyeffect/code/cassandra/conf/cassandra.yaml, please change this to the IP that will be used on this node for Cassandra"
echo "On line 428, again in both files, please change the seeds to include the IP of all nodes to be used in Cassandra"

set +x
