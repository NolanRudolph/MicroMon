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
    cd $CSRC

    #Delete data folder
    mkdir $SHARED_DATA
    rm -rf $CSRC/data/*
    mkdir -p $CSRC/data/data
    $CSRC/bin/cassandra
    sleep 5
}


RUN_YCSB() {
	cd $YCSBHOME
	sleep 5

  # Create keyspace
  $CSRC/bin/cqlsh $HOST -e "create keyspace ycsb WITH REPLICATION = {'class'
  : 'SimpleStrategy', 'replication_factor': 3 }; 
  USE ycsb; 
  create table usertable (y_id varchar primary key, field0 varchar, field1 varchar, field2
  varchar,field3 varchar,field4 varchar, field5 varchar, field6 varchar,field7
  varchar,field8 varchar,field9 varchar);"

  sleep 5

  # Warmup Phase
  $YCSBHOME/bin/ycsb load cassandra2-cql -p hosts=$HOST -p port=$PORT -p recordcount=$OPSCNT -P $YCSBHOME/workloads/workloada -s

  sleep 5

  # Run Phase
  $YCSBHOME/bin/ycsb run cassandra2-cql -p hosts=$HOST -p port=$PORT -p recordcount=$OPSCNT -P $YCSBHOME/workloads/workloada  

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
sleep 5
RUN_CASSANDARA
sleep 30
RUN_YCSB
set +x
