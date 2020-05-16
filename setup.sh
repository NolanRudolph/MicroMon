#!/bin/bash

# PREREQUISITES
# 1. Be sure to mount the proper HDD/SSD onto your home directory
# 2. Be ready to input username/password for repository cloning

## INSTALL REQUIRED SOFTWARE ##

sudo apt-get update
sudo apt-get install -y openjdk-8-jdk maven ant

# Switch to compatible JDK version
printf "\n*** IT IS OKAY TO RECEIVE \"error: no alternatives\" ERROR ***\n"
sudo update-java-alternatives -s java-1.8.0-openjdk-amd64
java -version # This should output " openjdk version "1.8.0_252" "

<<test
## SETTING UP EDITED CASSANDRA ##

# This will be placed in home directory
cd ~

# Pull the main repository
git clone https://github.com/SudarsunKannan/butterflyeffect.git
cd butterflyeffect

# Switch to the proper branch
git checkout FullDynamic

# Create a required directory
sudo mkdir /root/.m2
sudo mkdir /root/.m2/repository
sudo chown -R $USER /root/.m2

# Compile the source code
cd code/cassandra
bash setup.sh

test

git clone https://github.com/SudarsunKannan/butterflyeffect.git
## SETTING UP VANILLA ##

# This will be placed in home directory
cd ~

# Get the source code
wget https://fossies.org/linux/misc/apache-cassandra-3.11.6-src.tar.gz
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
cp $CODE/cassandra/conf/cassandra.yaml vanilla/code/cassandra/conf/cassandra.yaml
sed -i "s/butterflyeffect/vanilla/g" vanilla/code/cassandra/conf/cassandra.yaml
cp $CODE/cassandra/conf/cassandra-topology.properties vanilla/code/cassandra/conf/cassandra-topology.properties
cp $CODE/cassandra/setup.sh vanilla/code/cassandra

# Compile source code
cd vanilla/code/cassandra
bash setup.sh


