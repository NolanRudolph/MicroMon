# MapKeeper

## Compiling YCSB and Running test YCSB script

    $ cd mapkeeper # Directory where mapkeeper is cloned
    $ ./ycsb_install.sh  

(test execution script is in mapkeeper/ycsb/YCSB/cassandara/start\_sevice.sh)

## Details and assumptions

The scripts assumes that cassandra is already installed.
If not enable the cassandra install functions within the 
install script and call them. they should do the job.

## YCSB execution script.

    $ ./start_sevice.sh

This script first starts the cassandara service, runs the YCSB warmup client 
followed by the run client


## Workloads
 
    $ ls  mapkeeper/ycsb/YCSB/workloads/


All the workloads are available. To change the workload, just modify the 
$WORKLOAD variable in start\_sevice.sh


## YCSB details

Refer to mapkeeper/README\_ycsb.md for details
