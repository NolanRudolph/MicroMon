#!/bin/bash
set -x
YCSB_CLIENT=$CODE/mapkeeper/ycsb/YCSB
OPSCNT=500000

#Note. for remote host, make the changes in
#/etc/cassandra.yaml for the server to listen 
#on its ip.

DESTROY() {
	#Make sure we don't have one already running
    echo "Killing Java Processes..."
	sudo killall java
	sudo killall java
	sleep 2
	sudo killall java
	sleep 2
	sudo killall java
	sleep 2

    # Clear cache
    echo "Clearing Cache..."
    FlushDisk
    sleep 5
}


RUN_CASSANDARA() {
    #$YCSBHOME/cassandra/start_sevice.sh
    cd $CSRC

    #Delete data folder
    mkdir $SHARED_DATA
    #rm -rf $SHARED_DATA/*
    rm -rf $CSRC/data
    rm -rf $CSRC/data/data
    unlink $CSRC/data
    unlink $SHARED_DATA
    #ln -s $SHARED_DATA $CSRC/data
    mkdir -p $CSRC/data/data
    $CSRC/bin/cassandra
    #/usr/sbin/cassandra 	
    #/usr/sbin/cassandra "--preferred=1"
    sleep 5
}


RUN_YCSB() {
	cd $YCSBHOME
	sleep 5

	#Warm up phase. Load the db
    python ~/MultiDimMonitor/Cassandra/fill_database.py
	sleep 5

	#Run phase
    for i in {1..50}
    do
        printf "Iteration %d\n", $i
        if ! (( $i % 2 ))
        then
            python ~/MultiDimMonitor/Cassandra/synch_test.py 192.168.1.2
        else
            python ~/MultiDimMonitor/Cassandra/synch_test.py 192.168.1.3
        fi
        sleep 3
    done
}

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}


cd $CODE
DESTROY
kill -9 `pidof java`
#Install ycsb and casandara
sleep 5
RUN_CASSANDARA
sleep 40
RUN_YCSB
