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

crom="/home/ubuntu/software/cromwell-43.jar"
jsonsDir="logs-wdl/jsons"
mkdir -p ${jsonsDir}

progress="logs-wdl/progress_bioinfoScaling.txt"
echo "Starting BioInfo Scalability Analysis" >> ${progress}
echo "##############################################################################################" >> ${progress} 
java -jar ${crom} --version >> ${progress}
echo "##############################################################################################" >> ${progress} 

ifstat -t -T -n -w > logs-wdl/network-report.txt
#for sleepDuration in 0 500 1000; do
	log1="logs-wdl/bioinfoScaling_processes-1_host.txt"
	log2="logs-wdl/bioinfoScaling_processes-2_host.txt"
	echo "cores,tasks,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,faults,inputs,outputs,socketsIn,socketsOut,exitStatus" | tee -a ${log1} ${log2}
	mkdir ${jsonsDir}/${sleepDuration}
	jsoninput="${jsonsDir}/${sleepDuration}/host_process_workflow.${sleepDuration}"
	sed "s/SleepDuration/${sleepDuration}/" host_process_workflow.json.tmpl > ${jsoninput}

	mkdir hosts

	for line in {1..14}; do
		cores=`cat cores.txt | sed -n ${line}p`  #goes to the forks param
		tasks=${cores}
		echo -n "${cores},${tasks}," | tee -a ${log1} ${log2}
		
		sed "s/NTASKS/${tasks}/" ${jsoninput} > ${jsoninput}.${tasks}.json
		sed "s/CORES/${cores}/" cromwell.config > ${jsonsDir}/cromwell.config.${cores}
		sed -i "s/LOG1/host1_tasks${tasks}.txt/" ${jsonsDir}/cromwell.config.${cores}
		sed -i "s/LOG2/host2_tasks${tasks}.txt/" ${jsonsDir}/cromwell.config.${cores}

		##### processes: 1
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%F,%I,%O,%r,%s,%x" --append --output ${log1} \
		        java -Dconfig.file=${jsonsDir}/cromwell.config.${cores} -jar ${crom} run host_process.wdl -i ${jsoninput}.${tasks}.json > hosts/host1_tasks${tasks}.txt
			

		#### Processes: 2
		/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%F,%I,%O,%r,%s,%x" --append --output ${log2} \
		        java -Dconfig.file=${jsonsDir}/cromwell.config.${cores} -jar ${crom} run host_workflow.wdl -i ${jsoninput}.${tasks}.json > hosts/host2_tasks${tasks}.txt

		echo -e "Done processing * ${tasks} * tasks, on * ${cores} * cores" >> ${progress}	
	done
	echo "##############################################################################################" >> ${progress}
#done

./summarize_hosts_nodes.sh > summarize_hosts_nodes.txt

echo "Bio-Scalability analysis completed for WDL!" | mail -s "WfMS- Bio-Scalability" "azzaea@gmail.com"

