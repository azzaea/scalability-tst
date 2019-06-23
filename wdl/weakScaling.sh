#!/bin/bash

##############################################################################################
#### For weak scalability, fix the number of tasks/core, and incrementally change the number of
#### cores. We are testing both short and long duration jobs (0-1000ms).
#### The script read value for cores from a file: cores.txt; and tasks from ntasks.txt, both in 
#### the same directory
##############################################################################################

crom="~/software/wdl/cromwell-42.jar"
jsonsDir="logs-wdl/jsons"
mkdir -p ${jsonsDir}

for sleepDuration in 0 500 1000; do
	log1="logs-wdl/weakScaling_processes-1_sleep-${sleepDuration}.txt"
	log2="logs-wdl/weakScaling_processes-2_sleep-${sleepDuration}.txt"
	echo "cores,tasks,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,exitStatus" | tee -a ${log1} ${log2}
    
    mkdir ${jsonsDir}/${sleepDuration}
    jsoninput="${jsonsDir}/${sleepDuration}/sleep_process_workflow.${sleepDuration}"
    sed "s/SleepDuration/${sleepDuration}/" sleep_process_workflow.json.tmpl > ${jsoninput}

	for line in {1..17}; do
		cores=`cat cores.txt | sed -n ${line}p`  #goes to the forks param
		tasks= `cat ntasks.txt | sed -n ${line}p`
		echo -n "${cores},${tasks}," | tee -a ${log1} ${log2}
    
        sed "s/Ntasks/${tasks}/" ${jsoninput} > ${jsoninput}.${tasks}.json
        sed "s/CORES/${cores}/" cromwell.config > ${jsonsDir}/cromwell.config.${cores}

		##### processes: 1
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log1} \
            java -Dconfig.file=${jsonsDir}/cromwell.config.${cores} -jar ${crom} run sleep_process.wdl -i ${jsoninput}.${tasks}.json


		#### Processes: 2
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log2} \
            java -Dconfig.file=${jsonsDir}/cromwell.config.${cores} -jar ${crom} run sleep_workflow.wdl -i ${jsoninput}.${tasks}.json

	done
done


