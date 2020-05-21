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
2. The same instructions are provided by the end of this script, but change the HOST variable in ~/butterflyeffect/code/scripts/setvars.sh to the IP of the host node in the Cassandra cluster. Then run "source scripts/setvars.sh" from ~/butterflyeffect/code.
3. Once the server and replicas have followed the SERVERS & REPLICAS section, make sure you are in directory ~/butterflyeffect/code and run "bash scripts/customTest.sh"
    a. Note: This is where you should change

## SERVER & REPLICAS
1. Make sure you follow REQS.txt found in the root directory of this repository
2. Run "bash scripts/replica\_setup.sh"
3. The same instructions are provided by the end of the script, but on each replica node and the server, you must change some configuration files found in ~/butterflyeffect/code/cassandra/conf.  
    a. Change cassandra.yaml so that  
        &nbsp;1. seeds on line 428 includes the IP address of all nodes in the cluster with a comma delimiter  
        2. listen_address on line 615 to the IP address of this node  
        3. rpc_address on line 692 to the IP address of this node  
    b. Only on server, change cassandra-topology.properties so that they replicate a format identical to lines 18-20; That is, <IP>=DC#:RAC#. Create an entry like this for each node in the cluster, including itself.  
    c. Change cassandra-rackdc.properties so that  
        1. dc=dc# on line 19, # reflects the same datacenter as its configuration in the server's cassandra-topology.properties  
        2. rack=rack# on line 20, # reflects the same rack as its configuration in the server's cassandra-topology.properties

## RUNNING TESTS
