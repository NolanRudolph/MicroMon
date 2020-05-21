# SETUP
This file explains how to setup my project. Please follow the *CLIENT* or *SERVER & REPLICAS* section respective of the node you're setting up. Both types of nodes should begin by following the *BOTH* section.

## BOTH
1. cd ~
2. git checkout https://github.com/SudarsunKannan/butterflyeffect.git  
    a. Provide proper credentials
3. cd butterflyeffect
4. git checkout FullDynamic
5. cd code

## CLIENT
1. Run "bash scripts/client\_setup.sh"
2. Change the HOST variable in ~/butterflyeffect/code/scripts/setvars.sh to the IP of the host node in the Cassandra cluster. Then run "source scripts/setvars.sh" from ~/butterflyeffect/code.

## SERVER & REPLICAS
1. Make sure you follow REQS.txt found in the root directory of this repository
2. From ~/butterflyeffect/code, run "bash scripts/replica\_setup.sh"
3. On each replica node and the server, you must change some configuration files found in ~/butterflyeffect/code/cassandra/conf.  
    a. Change cassandra.yaml so that  
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. seeds on line 428 includes the IP addresses of all nodes in the cluster with a comma delimiter  
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. listen_address on line 615 is the IP address of this node  
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3. rpc_address on line 692 is the IP address of this node  
    b. Only on server, change cassandra-topology.properties so that they replicate a format identical to lines 18-20; That is, &nbsp;&nbsp;&nbsp;&nbsp;IP=DC#:RAC#. An entry like this should be created for each node found within "seeds" from line 428 of cassandra.yaml. &nbsp;&nbsp;&nbsp;&nbsp;I.e., create an entry for each node in the cluster, including itself.  
    c. Change cassandra-rackdc.properties so that  
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. dc=dc# on line 19, # reflects the same datacenter as its configuration in the server's cassandra-topology.properties  
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. rack=rack# on line 20, # reflects the same rack as its configuration in the server's cassandra-topology.properties

## RUNNING TESTS
1. Make sure that setvars.sh has been sourced from ~/butterflyeffect/code. You can check this by calling "echo $CODE" and making sure it equates to ~/butterflyeffect/code.
2. Make sure that the cassandra.yaml, casssandra-rackdc.properties, and cassandra-topology.properties (on the server) have all been updated to hold the correct content (see *SERVERS & REPLICAS* step 3)
3. On the server node and all replica nodes, from ~/butterflyeffect/code, as simultaneously as possible call "bash scripts/restart.sh". This kills any Cassandra processes, deletes the Cassandra data folders, and restarts Cassandra. Therefore, this works as the name suggests: A restart from a previous test, but it also works perfectly fine for a lone test as well.
4. Wait until you see "No gossip backlog; proceeding" from the Cassandra logger on all nodes.
5. Now, on the client node, make sure "echo $HOST" returns the IP of the server. If it does not, edit the HOST variable in ~/butterflyeffect/code/scripts/setvars.sh, and then run "source scripts/setvars.sh" from ~/butterflyeffect/code (see *CLIENT* step 2) 
6. On all nodes, run "bash ~/butterflyeffect/code/scripts/flush.sh"
7. On the client node, make sure line 4, 23, and 32 of ~/butterflyeffect/codescripts/customTest.sh are updated to your liking. Line 4 holds the variable "OPSCNT", which is the number of entries that will be loaded during the load phase of Cassandra. The load phase of cassandra is executed on line 23 - To change workloads, change "workloada" to "workloadX", replacing X with a letter from [a, b, c, d, e]. The same explanation applies to line 32. You can inspect and manipulate what these different workloads entail by viewing ~/butterflyeffect/code/mapkeeper/ycsb/YCSB/workloads/workloadX, again with X being replaced with a letter from [a, b, c, d, e].
8. From ~/butterflyeffect/code, run "bash scripts/customTest.sh".
9. IMPORTANT: Between the load phase and run phase, make sure to run "bash ~/butterflyeffect/code/scripts/flush.sh" on all nodes but the script node.

## SWITCHING TO VANILLA
Note: This will be followed on all nodes except Client
1. Run "cd ~/vanilla/code"
2. Run "source scripts/setvars.sh"
3. If you have followed step 3 from *SERVER & REPLICA*, run the following commands:  
    a. "cp ~/butterflyeffect/code/cassandra/conf/cassandra.yaml ~/vanilla/code/cassandra/conf/cassandra.yaml"  
    b. "cp ~/butterflyeffect/code/cassandra/conf/cassandra-rackdc.yaml ~/vanilla/code/cassandra/conf/cassandra-rackdc.properties"  
    c. On server, "cp ~/butterflyeffect/code/cassandra/conf/cassandra-topology.properties ~/vanilla/code/cassandra/conf/cassandra-topology.properties"  
    d. "vim ~/vanilla/code/cassandra/conf/cassandra.yaml", and in this file, type ":%s/butterflyeffect/vanilla/g", then ":wq" 
4. If you have not followed step 3 from *SERVER & REPLICA*, I strongly encourage you to do this first. If not, follow step 3 from *SERVER & REPLICA*, except replace all instances of "butterflyeffect" with "vanilla"
