#!/bin/bash

##############################################################################################
#### For strong scalability, fix the number of tasks, and incrementally change the number of
#### cores. We are testing both short and long duration jobs (0-1000ms).
#### The script read value for cores from a file: cores.txt in the same directory
##############################################################################################

nextflow="~/software/nextflow/19.04.1"

for sleepDuration in 0 500 1000; do
	log1="logs-wdl/strongScaling_processes-1_sleep-${sleepDuration}.txt"
	log2="logs-wdl/strongScaling_processes-2_sleep-${sleepDuration}.txt"
	echo "cores,tasks,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,exitStatus" | tee -a ${log1} ${log2}

	for line in {1..17}; do
		cores=`cat cores.txt | sed -n ${line}p`  #goes to the forks param
		tasks=65536
		echo -n "${cores},${tasks}," | tee -a ${log1} ${log2}

		##### processes: 1
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log1} \
			${nextflow} run sleep_process.nf -profile cluster --ntasks=${tasks} --forks=${cores} --duration=${sleepDuration}

		#### Processes: 2
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log2} \
			${nextflow} run sleep_workflow.nf -profile cluster --ntasks=${tasks} --forks=${cores} --duration=${sleepDuration}
	
	done
done

json1="logs-wdl/strongScaling_${sleepDuration}.json"

sed "s/SleepDuration/${sleepDuration}/" strongScaling.tmpl > ${json1}

while read n; do
	jsonsDir="logs-nf/${sleepDuration}"
	mkdir ${jsonsDir}
	sed "s/ntasks/${n}/" ${json1} >	"${jsonsDir}/${json1}.${n}"
#	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log} \
#		java -Dconfig.file=slurm.config -jar /home/a-m/azzaea/software/wdl/cromwell-39.jar run strongScaling.wdl -i ${jsonsDir}/${json1}.${n}
done < ntasks.txt




