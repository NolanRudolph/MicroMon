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
    #rm -rf $CSRC/data
    rm -rf $CSRC/data/*
    #unlink $CSRC/data
    #unlink $SHARED_DATA
    #ln -s $SHARED_DATA $CSRC/data
    mkdir -p $CSRC/data/data
    $CSRC/bin/cassandra -Dcassandra.ignore_dc=true
    #/usr/sbin/cassandra 	
    #/usr/sbin/cassandra "--preferred=1"
    sleep 5
}


RUN_YCSB() {
	cd $YCSBHOME

	#Execute these commands to create ycsb keyspace with cassandra db
	cqlsh $HOST -e "create keyspace ycsb WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor': 3 }; USE ycsb; create table usertable (y_id varchar primary key, field0 varchar, field1 varchar, field2 varchar,field3 varchar,field4 varchar, field5 varchar, field6 varchar,field7 varchar,field8 varchar,field9 varchar);" #> ~/output

	#wait
	sleep 5
	#Warm up phase. Load the db
	$YCSBHOME/bin/ycsb load cassandra-cql -p hosts=$HOST -p port=$PORT -p recordcount=$OPSCNT -P $YCSBHOME/workloads/workloada -s
	#Wait
	sleep 5
	#Run phase
	$YCSBHOME/bin/ycsb run cassandra-cql -p hosts=$HOST -p port=$PORT -p recordcount=$OPSCNT -P $YCSBHOME/workloads/workloada
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
sleep 60
RUN_YCSB
