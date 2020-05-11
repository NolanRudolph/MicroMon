#!/bin/bash
set -x

#OUTPUT=$1
LEVELDBHOME=/home/sudarsun/devel/Docs/leveldb-nvm
OUTPUTDIR=/home/sudarsun/devel/Docs/leveldb-nvm/graphs/YCSB/pattern/VALUESIZE
OUTPUT=$OUTPUTDIR/out.txt
LEVELDBMAPKEEPER=/home/sudarsun/devel/Docs/leveldb-nvm/mapkeeper/leveldb
YCSBHOME=/home/sudarsun/devel/Docs/leveldb-nvm/mapkeeper/ycsb/YCSB

let NUMTHREADS=$1
WORKLOAD=$2
let VALUESZ=$3

export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
source ~/.bashrc

cd $LEVELDBHOME
make -j4
sudo cp out-static/libleveldb.a /usr/local/lib/
sudo cp -r include/leveldb /usr/local/include


COMPILE(){
cd $LEVELDBMAPKEEPER
make clean
make -j2
}

CLEAN(){
sudo killall mapkeeper_leveldb
sudo killall mapkeeper_level
sudo rm -rf /mnt/ramdisk/*
sleep 2
sudo killall mapkeeper_leveldb
sudo killall mapkeeper_level
}

TAKEREST(){
   sleep 10
}

RUN_LEVELDB(){
rm -rf /mnt/ramdisk/* && rm -rf data/* 
cd $LEVELDBMAPKEEPER
timeout 500s ./mapkeeper_leveldb --datadir=/mnt/ramdisk --num_levels=2 --num_read_threads=$NUMTHREADS &
}

RUN_YCSB() {
  cd $YCSBHOME
  sleep 5
  LOADOUTPUT=$OUTPUTDIR/"load_valusez_"$VALUESZ"_"$NUMTHREADS"thread_"$WORKLOAD".out"
  STOREOUTPUT=$OUTPUTDIR/"store_valusez_"$VALUESZ"_"$NUMTHREADS"thread_"$WORKLOAD".out"
  echo "$VALUESZ"	
  if (($VALUESZ > 0)) ; then
     sed -i "/fieldlength=/c\fieldlength=$VALUESZ" ./workloads/heterodb/$WORKLOAD	
  fi
  sed -i "/recordcount=/c\recordcount=300000" ./workloads/heterodb/$WORKLOAD
  sed -i "/operationcount=/c\operationcount=200000" ./workloads/heterodb/$WORKLOAD
  bin/ycsb load mapkeeper -P ./workloads/heterodb/$WORKLOAD #&> $LOADOUTPUT
  TAKEREST
  bin/ycsb run mapkeeper -P ./workloads/heterodb/$WORKLOAD #&> $STOREOUTPUT
}

RUN_YCSB_VANILLA() {
  cd $YCSBHOME
  sleep 5
  LOADOUTPUT=$OUTPUTDIR/"load_valusez_"$VALUESZ"_vanilla_"$WORKLOAD".out"
  STOREOUTPUT=$OUTPUTDIR/"store_valusez_"$VALUESZ"_vanilla_"$WORKLOAD".out"
  echo "$VALUESZ"	
  if (($VALUESZ > 0)) ; then
     sed -i "/fieldlength=/c\fieldlength=$VALUESZ" ./workloads/heterodb/$WORKLOAD	
  fi
  sed -i "/recordcount=/c\recordcount=1000000" ./workloads/heterodb/$WORKLOAD
  sed -i "/operationcount=/c\operationcount=200000" ./workloads/heterodb/$WORKLOAD
  bin/ycsb load mapkeeper -P ./workloads/heterodb/$WORKLOAD &> $LOADOUTPUT
  TAKEREST
  bin/ycsb run mapkeeper -P ./workloads/heterodb/$WORKLOAD &> $STOREOUTPUT
}


INSTALL_VANILLA_LEVELDB(){
cd $LEVELDBHOME
sudo cp vanilla-static/libleveldb.a /usr/local/lib/
sudo cp -r include/leveldb /usr/local/include
}

#ASSUME WORKLOAD AND NUMTHREADS PARAMS are set
RUNALONE() {
	CLEAN
	RUN_LEVELDB
	RUN_YCSB
	CLEAN 
}

EXTRACT(){
    echo "****************************************"
    #cd $OUTPUTDIR/$VALUESZ
    cd $OUTPUTDIR
    for NUMTHREADS in 0 1 2
    do
      for NUM in a b c d e f
      do
        OUT="workload_"$NUM"_threads_"$NUMTHREADS"_.out"
        for f in $(find . -name "store_valusez_"$VALUESZ'*'$NUMTHREADS'th*workload'$NUM".out"); do grep -r "OVERALL" $f | tail -1; done | awk '{print $3}' &> $OUT
      done
    done
    echo "****************************************"
}

CONSOLIDATE(){
    cd $OUTPUTDIR #/$VALUESZ
    rm "result-"$VALUESZ".csv"
    for NUM in a b c d e f
    do
      paste -d, "workload_"$NUM"_threads_0_.out" "workload_"$NUM"_threads_"[1-2]"_.out" >> "result-"$VALUESZ".csv"
      rm "workload_"$NUM"_threads_"[0-2]"_.out"
    done
}

EXTRACT1(){
rm $OUTPUTDIR/result.csv
for NUM in a b c d e f
  do
    for NUMTHREADS in 0 1 2
     do
        #TAKEREST
        WORKLOAD="workload"$NUM
        STOREOUTPUT=$OUTPUTDIR/"store_valusez_"$VALUESZ"_"$NUMTHREADS"thread_"$WORKLOAD".out"    
        grep -r "\[OVERALL\], Throughput" $STOREOUTPUT | awk '{print $3}' &>> $OUTPUTDIR/result.csv
  done
  echo "******************************" &>> $OUTPUTDIR/result.csv
done
}



RUNHETERODB() {
for VALUESZ in 2048 1024 100
do
for NUMTHREADS in 2 1 0
#for NUMTHREADS in 2
do
for NUM in b c d e f a
  do
        TAKEREST
        WORKLOAD="workload"$NUM
	CLEAN
	RUN_LEVELDB
        TAKEREST
	RUN_YCSB
        CLEAN 
   done
  done
done
}

RUNVANILLA() {
cd $LEVELDBMAPKEEPER
for VALUESZ in 4096 2048 1024 100
do
for NUM in a b c d e f
  do
        TAKEREST
        WORKLOAD="workload"$NUM
	CLEAN
	RUN_LEVELDB
        TAKEREST
	RUN_YCSB_VANILLA
        CLEAN 
   done
  done
}
#ASSUME WORKLOAD AND NUMTHREADS PARAMS are set
RUNALONEVANILA() {
	CLEAN
	RUN_LEVELDB
	RUN_YCSB_VANILLA
	CLEAN 
}



#INSTALL_VANILLA_LEVELDB
COMPILE
RUNALONE
#RUNHETERODB
#RUNVANILLA
#RUNALONEVANILA
#EXTRACT
#CONSOLIDATE
exit

#rsync --rsh="/usr/bin/sshpass -p $STEWARTPASS ssh -o StrictHostKeyChecking=no -l stewart"  -r /home/sudarsun/codes/apps/leveldb-nvm/graphs stewart@stewart.cc.gt.atl.ga.us:/home/stewart/Dropbox/conf/lsm/

