#!/bin/bash

set -x

##############################################################################################
#### For strong scalability, fix the number of tasks, and incrementally change the number of
#### cores. We are testing both short and long duration jobs (0-1000ms).
#### The script read value for cores from a file: cores.txt in the same directory
##############################################################################################

nextflow="/home/ubuntu/software/nextflow"
progress="logs-nf/progress_strongScaling.txt"
echo "Starting Strong Scalability Analysis" >> ${progress}
echo "##############################################################################################" >> ${progress} 

for sleepDuration in 0 500 1000; do
	progress="logs-nf/progress_strongScaling.txt"
	echo "Sleep duration = ${sleepDuration}" >> ${progress}

	log1="logs-nf/strongScaling_processes-1_sleep-${sleepDuration}.txt"
	log2="logs-nf/strongScaling_processes-2_sleep-${sleepDuration}.txt"
	echo "cores,tasks,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,exitStatus" | tee -a ${log1} ${log2}

	for line in {1..19}; do
		cores=`cat cores.txt | sed -n ${line}p`  #goes to the forks param
		tasks=65536
		echo -n "${cores},${tasks}," | tee -a ${log1} ${log2}

		##### processes: 1
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log1} \
			${nextflow} run sleep_process.nf -profile cluster --ntasks=${tasks} --forks=${cores} --duration=${sleepDuration}

		#### Processes: 2
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log2} \
			${nextflow} run sleep_workflow.nf -profile cluster --ntasks=${tasks} --forks=${cores} --duration=${sleepDuration}
		echo -e "Done processing * ${tasks} * tasks, on * ${cores} * cores" >> ${progress}	
	done
	echo "##############################################################################################" >> ${progress}
done

echo "Strong Scalability analysis completed for Nextflow!" >> ${progress}

