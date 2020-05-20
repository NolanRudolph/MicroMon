#!/bin/bash

set -xe

# Home directory install
cd ~

# Install Required Software
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk python-pip
sudo update-java-alternatives -s java-1.8.0-openjdk-amd64
java -version # This should output " openjdk version "1.8.0_252" "
pip install cqlsh

echo "*** THIS HAS A CHANCE OF FAILING, IF IT DOES SEE COMMENTS IN THIS SCRIPT ***"
# Please go to: https://fossies.org/linux/misc/apache-cassandra-3.11.6-src.tar.gz/
# Then press the link at the top, "Contents of <link>" and download to your local computer
# Use "$ scp path/to/downloads/apache-cassandra-3.11.6-src.tar.gz <cloudlab node>:~"
# Then restart the script
wget https://fossies.org/linux/misc/apache-cassandra-3.11.6-src.tar.gz
tar -xzf apache-cassandra-3.11.6-src.tar.gz

# We need this python lib
rm -rf .local/lib/python2.7/site-packages/cqlshlib
mv apache-cassandra-3.11.6-src/pylib/cqlshlib ~/.local/lib/python2.7/site-packages
rm -rf apache-cassandra-3.11.6-src.tar.gz apache-cassandra-3.11.6-src

# Clone butterflyeffect
echo "Please enter GitHub username and password for butterflyeffect:"
git clone https://github.com/SudarsunKannan/butterflyeffect.git
cd butterflyeffect/code
git checkout FullDynamic
source scripts/setvars.sh

set +x
echo "You can now run tests. Make sure you change variable HOST in ~/butterflyeffect/code/scripts/setvars.sh to the IP of the server node for the Cassandra benchmark. Then run \"source ~/butterflyeffect/code/scripts/setvars.sh\" again."

set +e
