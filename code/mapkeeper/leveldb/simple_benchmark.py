import xml.etree.ElementTree as ET
import subprocess
import os, datetime
import json
import re

from subprocess import Popen, PIPE
#from graph import graph_gen
#from graph import bar_graph_gen
from simple_graph import sensitivity_graph_gen

tree = ET.parse('test_input.xml')
root = tree.getroot()

APP= "./runtest.sh"

RESULTDIR = "/home/sudarsun/codes/apps/leveldb-nvm/graphs/YCSB/pattern/VALUESIZE/"


def ReadJSON(myfilename):
  with open(myfilename) as f:
    lst = json.load(f)
    print lst

def Cleanup():
   os.system("./cleanup.sh")

#ReadJSON("output.json");
#exit() 

sensitivity = root.find('./sensitivity-main')
enable_sensitivity = False if int(sensitivity.get('enable')) == 0 else True

valusesz = root.find('./valusesz-main')
enable_valuzesz = False if int(valusesz.get('enable')) == 0 else True

############# Check the tests that are enabled #############
benchmarks = []
for child in root.findall('benchmarks'):
    for subchild in child:
        benchmarks.append(subchild.text)

enable_graph_generate = 0;

if enable_valuzesz:
    value_seed_size = sensitivity.find('seed-size').text
    num_tests = sensitivity.find('num-tests').text
    thread_count = sensitivity.find('thread-count').text
    mem0_buff_size = sensitivity.find('buffer-size-mem0').text
    mem1_buff_size = sensitivity.find('buffer-size-mem1').text
    memory_levels = sensitivity.find('num-levels').text
    num_elements = sensitivity.find('num-elements').text
    num_readthrds = sensitivity.find('num-readthreads').text    
    output_mode = sensitivity.find('outputmode').text    
    readstat = sensitivity.find('readstat').text    
    updatestat = sensitivity.find('updatestat').text

    
if enable_sensitivity:
    value_seed_size = sensitivity.find('seed-size').text
    num_tests = sensitivity.find('num-tests').text
    thread_count = sensitivity.find('thread-count').text
    mem0_buff_size = sensitivity.find('buffer-size-mem0').text
    mem1_buff_size = sensitivity.find('buffer-size-mem1').text
    memory_levels = sensitivity.find('num-levels').text
    num_elements = sensitivity.find('num-elements').text
    num_readthrds = sensitivity.find('num-readthreads').text    
    output_mode = sensitivity.find('outputmode').text    
    readstat = sensitivity.find('readstat').text    
    updatestat = sensitivity.find('updatestat').text

    #Just print the output
    if int(output_mode):
	 enable_sensitivity = False
	 enable_graph_generate = True
    else:
	enable_graph_generate = False	
	

############# Testing Logic begins here #############

benchmark_string = "--benchmarks=" + benchmarks[0]
for i in range(1, len(benchmarks)):
    benchmark_string = benchmark_string + "," + benchmarks[i]

graph_dir = os.path.join(os.getcwd(), 'output-graphs')
if not os.path.exists(graph_dir):
    os.makedirs(graph_dir)

#Enable this only if we need to much granularity in the versions of the results.
#cur_dir = os.path.join(graph_dir, datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S'))
cur_dir = os.path.join(graph_dir, datetime.datetime.now().strftime('%Y-%m-%d'))

try:
    os.makedirs(cur_dir)
except OSError, e:
    if e.errno != 17:
        raise

if enable_sensitivity:
    super_set_y = []
    i = 0
    value_size = int(value_seed_size)
    bench = "readrandom"
    super_set_x = []
    y_labels = []
    title = "" 

    #Enable this for read thread test
    #for read_threads in range(0, int(num_readthrds)+1):
    for read_threads in range(0, int(num_readthrds)+1):

	#Enable this for value size test
        x_values = value_size;
        x_label = 'Data Element Size'

        xarr = []
        yarr = []

	workloads = ["workloada", "workloadb", "workloadc", "workloadd", "workloade","workloadf"]

    	#for count in range(int(num_tests)):
    	for workload in workloads:

          filename = RESULTDIR + "workloada_nvmimmutable_" + str(read_threads) + "thread_" + str(workload) + ".out"
          #filename = os.path.join(cur_dir, 'Mem2_buff_size-vs-threads.png')

          lat95th = []
          lat99th = []
          throughput = [] 
          runtime = []

          xarr.append(x_values);
          x_values = x_values + value_size
	  print workload

          process = Popen([APP, str(read_threads), str(workload)], stdout=PIPE)
          (output, err) = process.communicate()
          exit_code = process.wait()

          target = open(filename, 'w')
          target.write(output)
          target.close()

          #print output
          for line in output.splitlines():
            my_set = line.split();
            if len(my_set) > 2:

               m = re.match("(\WCLEANUP\W+)",my_set[0])
               if m:
	           continue;                
	       m = re.match("(\WINSERT\W+)",my_set[0])
               if m:
	           continue;                
               m = re.match("(95th\w+)",my_set[1])
               if m:
	           lat95th.append(my_set[2]) 		  
               m =  re.match("(99th\w+)",my_set[1]) 
               if m:
	           lat99th.append(my_set[2]) 		  
	       m =  re.search("Throughput", my_set[1])
               if m:
	           throughput.append(my_set[2]) 		  

        print lat95th
        print lat99th 
        print throughput
	print "********************"           	
        #i = i + 1
        #super_set_y.append(yarr); 
        #super_set_x.append(xarr); 
    #num_lines = len(super_set_y)
    #print super_set_y
    #print super_set_x
    #graph_gen(x_label, title, filename, 1, y_labels,  super_set_x, super_set_y)
    #bar_graph_gen(x_label, title, filename, num_benchmarks, benchmarks, x_values, super_set)

if enable_graph_generate:

    title = "" 

    for read_threads in range(0, int(num_readthrds)+1):

	workloads = ["workloada", "workloadb", "workloadc", "workloadd", "workloade", "workloadf"]

        lat95th = []
        lat99th = []
        throughput = [] 
        runtime = []

    	for workload in workloads:

          filename = RESULTDIR + "workloada_nvmimmutable_" + str(read_threads) + "thread_" + str(workload) + ".out"

          target = open(filename, 'r')
          #target.write(output)

          #for line in output.splitlines():
          for line in target.readlines():

            my_set = line.split();
            if len(my_set) > 2:
	       if(int(readstat) > 0):
                 r = re.match("(\WREAD])",my_set[0])
                 s = re.match("(\WSCAN])",my_set[0])
                 if r is None and s is None:
	             continue;     

	       if(int(updatestat) > 0):
                 u = re.match("(\WUPDATE])",my_set[0])
		 m = re.match("(\WREAD-MODIFY-WRITE])",my_set[0])
                 if u is None and m is None:
	             continue;     

               m = re.match("(95th\w+)",my_set[1])
               if m:
	           lat95th.append(float(my_set[2])) 		  
               m =  re.match("(99th\w+)",my_set[1]) 
               if m:
	           lat99th.append(float(my_set[2])) 		  

	       m =  re.search("Throughput", my_set[1])
               if m:
	           throughput.append(float(my_set[2])) 		  

        print lat95th
        print lat99th 
        print throughput
        print "********************"           	

        target.close()


if enable_valuzesz:
    super_set_y = []
    i = 0
    value_size = int(value_seed_size)
    bench = "readrandom"
    super_set_x = []
    y_labels = []
    title = "" 
    threadranges = [0, 3]
    valueranges = [8192, 4096, 1024, 16384]	

    for valuesz in valueranges:

	    #Enable this for read thread test
	    #for read_threads in range(0, int(num_readthrds)+1):
	    for read_threads in threadranges:

		workloads = ["workloada", "workloadb", "workloadc", "workloadd", "workloade","workloadf"]
		#workloads = ["workloada", "workloadb"]
		#for count in range(int(num_tests)):
		for workload in workloads:

		  filename = RESULTDIR + "valuzesz_" + str(valuesz) + "_threads_"  + str(read_threads) + "_workload_" + str(workload) + ".out"

		  lat95th = []
		  lat99th = []
		  throughput = [] 
		  runtime = []

		  print workload

		  process = Popen([APP, str(read_threads), str(workload), str(valuesz)], stdout=PIPE)
		  (output, err) = process.communicate()
		  exit_code = process.wait()
		  target = open(filename, 'w')
		  target.write(output)
		  target.close()

		  #print output
		  for line in output.splitlines():
		    my_set = line.split();
		    if len(my_set) > 2:

		       m = re.match("(\WCLEANUP\W+)",my_set[0])
		       if m:
			   continue;                
		       m = re.match("(\WINSERT\W+)",my_set[0])
		       if m:
			   continue;                
		       m = re.match("(95th\w+)",my_set[1])
		       if m:
			   lat95th.append(my_set[2]) 		  
		       m =  re.match("(99th\w+)",my_set[1]) 
		       if m:
			   lat99th.append(my_set[2]) 		  
		       m =  re.search("Throughput", my_set[1])
		       if m:
			   throughput.append(my_set[2]) 		  

		print lat95th
		print lat99th 
		print throughput
		print "********************"           	
