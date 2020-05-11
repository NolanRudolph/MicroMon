#!/bin/bash

HOMEDIR=$HOME
CLOUDLAB=$PWD
YCSBHOME=$CLOUDLAB/ycsb/YCSB

DOWNLOAD_YCSB() {
    cd $CLOUDLAB

    #check if repo already exists
    if [ ! -d "mapkeeper" ]; then
        git clone https://gitlab.com/sudarsunkannan/mapkeeper.git
    fi
}

INSTALL_YCSB() {
    cd $YCSBHOME
    mvn clean package
}

RUN_YCSB_CASSANDARA() {

    #Enable only if cassandra binary is required.
    #INSTALL_CASSANDRA_SOURCE
    cd $YCSBHOME/cassandra
    ./start_sevice.sh 
}



INSTALL_SYSTEM_LIBS(){
    sudo apt-get install -y git
    sudo apt-get install -y software-properties-common
    sudo apt-get install -y python3-software-properties
    sudo apt-get install -y python-software-properties
    sudo apt-get install -y unzip
    sudo apt-get install -y python-setuptools python-dev build-essential
    sudo easy_install pip
    sudo apt-get install -y numactl
    sudo apt-get install -y libsqlite3-dev
    sudo apt-get install -y libnuma-dev
    sudo apt-get install -y libkrb5-dev
    sudo apt-get install -y libsasl2-dev
    sudo apt-get install -y cmake
    sudo apt-get install -y build-essential
    sudo apt-get install -y maven
    #INSTALL_JAVA
}

cd $CLOUDLAB

#Install all system lib dependencies
INSTALL_SYSTEM_LIBS

#Install ycsb and casandara
INSTALL_YCSB
RUN_YCSB_CASSANDARA


#enable only if you do not have cassandra installed
INSTALL_CASSANDRA_BINARY(){

    mkdir $CLOUDLAB/cassandra	
    echo "deb http://www.apache.org/dist/cassandra/debian 39x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
    echo "deb-src http://www.apache.org/dist/cassandra/debian 39x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list

    gpg --keyserver pgp.mit.edu --recv-keys F758CE318D77295D
    gpg --export --armor F758CE318D77295D | sudo apt-key add -

    gpg --keyserver pgp.mit.edu --recv-keys 2B5C1B00
    gpg --export --armor 2B5C1B00 | sudo apt-key add -

    gpg --keyserver pgp.mit.edu --recv-keys 0353B12C
    gpg --export --armor 0353B12C | sudo apt-key add -

    sudo apt-get update
    sudo apt-get install -y --force-yes cassandra
}

DOWNLOAD_CASSANDRA_SOURCE(){
    mkdir $CLOUDLAB/cassandra	
    cd $CLOUDLAB/cassandra
    wget http://archive.apache.org/dist/cassandra/3.9/apache-cassandra-3.9-src.tar.gz
    tar -xvzf apache-cassandra-3.9-src.tar.gz
}

INSTALL_CASSANDRA_SOURCE(){
    mkdir $CLOUDLAB/cassandra
    cd $CLOUDLAB/cassandra

    if [ ! -d "/usr/share/cassandra" ]; then
        INSTALL_CASSANDRA_BINARY
    fi

    if [ ! -d "apache-cassandra-3.9-src" ]; then
        DOWNLOAD_CASSANDRA_SOURCE
    fi	

    cd apache-cassandra-3.9*
    ant
    #keep a backup if installed version exists and no backup exists
    if [ ! -d "/usr/share/cassandra-orig" ]; then
        sudo cp -rf  /usr/share/cassandra  /usr/share/cassandra-orig
    fi
    sudo cp ./build/apache-cassandra-3.9-SNAPSHOT.jar /usr/share/cassandra/apache-cassandra-3.9.jar
    sudo cp ./build/apache-cassandra-thrift-3.9-SNAPSHOT.jar /usr/share/cassandra/apache-cassandra-thrift-3.9.jar
}

INSTALL_JAVA() {
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update
    sudo apt-get install -y oracle-java8-set-default
    java -version
}

INSTALL_CMAKE(){
    cd $CLOUDLAB
    wget https://cmake.org/files/v3.7/cmake-3.7.0-rc3.tar.gz
    tar zxvf cmake-3.7.0-rc3.tar.gz
    cd cmake-3.7.0*
    ./configure
    ./bootstrap
    make -j16
    make install
}
