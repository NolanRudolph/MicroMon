#!/bin/bash
set -x
YCSB_CLIENT=$CODE/mapkeeper/ycsb/YCSB
OPSCNT=500000

cd $YCSBHOME

# Create keyspace
$CSRC/bin/cqlsh $HOST -e "create keyspace ycsb WITH REPLICATION = {'class'
: 'SimpleStrategy', 'replication_factor': 2 }; 
USE ycsb; 
create table usertable (y_id varchar primary key, field0 varchar, field1 varchar, field2
varchar,field3 varchar,field4 varchar, field5 varchar, field6 varchar,field7
varchar,field8 varchar,field9 varchar);"

sleep 5

$YCSBHOME/bin/ycsb load cassandra2-cql -p hosts=$HOST -p port=$PORT -p recordcount=$OPSCNT -P $YCSBHOME/workloads/workloada -s

sleep 5

$YCSBHOME/bin/ycsb run cassandra2-cql -p hosts=$HOST -p port=$PORT -p recordcount=$OPSCNT -P $YCSBHOME/workloads/workloada  

set +x
