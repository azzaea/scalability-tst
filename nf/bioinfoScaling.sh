#!/bin/bash

#module load Java # For working on biocluster- change for AWS

set -x

##############################################################################################
#### For bioinfo scalability: scalability scenarios meaningful in the context of bioinformatics.
#### Part I: Allocate 1 node, and benchmark time for tasks=1:#cores in this node
#### Part II: Increase the number of nodes in the cluster gradually (i.e. increase the number of
#### tasks by the number of cores in a node, and benchmark. 
#### The script read value for cores from a file: cores.txt in the same directory
##############################################################################################

nextflow="/home/ubuntu/software/nextflow"
progress="logs-nf/progress_bioinfoScaling.txt"
echo "Starting BioInfo Scalability Analysis" >> ${progress}
echo "##############################################################################################" >> ${progress} 

#for sleepDuration in 0 500 1000; do
	mkdir logs-nf
	progress="logs-nf/progress_bioinfoScaling.txt"

	log1="logs-nf/bioinfoScaling_processes-1_host.txt"
	log2="logs-nf/bioinfoScaling_processes-2_host.txt"
	echo "cores,tasks,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,exitStatus" | tee -a ${log1} ${log2}

	mkdir hosts

	for line in {1..10}; do
		cores=`cat cores.txt | sed -n ${line}p`  #goes to the forks param
		tasks=${cores}
		echo -n "${cores},${tasks}," | tee -a ${log1} ${log2}

		##### processes: 1
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log1} \
			${nextflow} run host_process.nf -profile cluster --ntasks=${tasks} --forks=${cores} --log=hosts/host1_tasks${tasks}.txt

		#### Processes: 2
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log2} \
			${nextflow} run host_workflow.nf -profile cluster --ntasks=${tasks} --forks=${cores} --log=hosts/host2_tasks${tasks}.txt
		echo -e "Done processing * ${tasks} * tasks, on * ${cores} * cores" >> ${progress}	
	done
	echo "##############################################################################################" >> ${progress}
#done

echo "Bio-Scalability analysis completed for Nextflow!" | mail -s "WfMS- Bio-Scalability" "azzaea@gmail.com"
