#!/bin/bash

set -x

##############################################################################################
#### For bioinfo scalability: scalability scenarios meaningful in the context of bioinformatics.
#### Part I: Allocate 1 node, and benchmark time for tasks=1:#cores in this node
#### Part II: Increase the number of nodes in the cluster gradually (i.e. increase the number of
#### tasks by the number of cores in a node, and benchmark. 
#### The script read value for cores from a file: cores.txt in the same directory
##############################################################################################

nextflow="/home/a-m/azzaea/software/nextflow/19.04.1"
progress="logs-nf/progress_bioinfoScaling.txt"
echo "Starting BioInfo Scalability Analysis" >> ${progress}
echo "##############################################################################################" >> ${progress} 

#for sleepDuration in 0 500 1000; do
	progress="logs-nf/progress_bioinfoScaling.txt"

	log1="logs-nf/bioinfoScaling_processes-1_host.txt"
	log2="logs-nf/bioinfoScaling_processes-2_host.txt"
	echo "cores,tasks,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,exitStatus" | tee -a ${log1} ${log2}

	for line in {1..10}; do
		cores=`cat cores.txt | sed -n ${line}p`  #goes to the forks param
		tasks=${cores}
		echo -n "${cores},${tasks}," | tee -a ${log1} ${log2}

		##### processes: 1
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log1} \
			${nextflow} run host_process.nf -profile cluster --ntasks=${tasks} --forks=${cores} --log=host1_tasks${tasks}.txt

		#### Processes: 2
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log2} \
			${nextflow} run host_workflow.nf -profile cluster --ntasks=${tasks} --forks=${cores} --log=host2_tasks${tasks}.txt
		echo -e "Done processing * ${tasks} * tasks, on * ${cores} * cores" >> ${progress}	
	done
	echo "##############################################################################################" >> ${progress}
#done

echo "Bio-Scalability analysis completed for Nextflow!" | mail -s "WfMS- Bio-Scalability" "azzaea@gmail.com"
