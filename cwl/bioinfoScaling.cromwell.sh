#!/bin/bash

module load Java # For working on biocluster- change for AWS
echo "Analysis done on: "
date

set -x

##############################################################################################
#### For bioinfo scalability: scalability scenarios meaningful in the context of bioinformatics.
#### Part I: Allocate 1 node, and benchmark time for tasks=1:#cores in this node
#### Part II: Increase the number of nodes in the cluster gradually (i.e. increase the number of
#### tasks by the number of cores in a node, and benchmark. 
#### This script reads values for cores from a file: cores.txt in the same directory
##############################################################################################

#crom="/home/ubuntu/software/cromwell-43.jar"
#crom="/usr/src/wdl/cromwell-42.jar"
crom="/home/a-m/azzaea/software/wdl/cromwell-47.jar"
resultsDir="results.cromwell"
ymlsDir="${resultsDir}/logs-cwl/ymls"
hostsDir=" ${resultsDir}/hosts"
mkdir -p ${resultsDir} ${ymlsDir} ${hostsDir}

progress="${resultsDir}/logs-cwl/progress_bioinfoScaling.txt"
echo "Starting BioInfo Scalability Analysis" >> ${progress}
echo "##############################################################################################" >> ${progress} 
java -jar ${crom} --version >> ${progress}
echo "##############################################################################################" >> ${progress} 

ifstat -t -T -n -w > ${resultsDir}/logs-cwl/network-report.txt

log1="${resultsDir}/logs-cwl/bioinfoScaling_processes-1_host.txt"
log2="${resultsDir}/logs-cwl/bioinfoScaling_processes-2_host.txt"
echo "cores,tasks,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,faults,inputs,outputs,socketsIn,socketsOut,exitStatus" | tee -a ${log1} ${log2}
ymlinput="${ymlsDir}/host_process_workflow"
cat host_process_workflow.yml.tmpl > ${ymlinput}

for line in {1..10}; do
	cores=`cat cores.txt | sed -n ${line}p`  #goes to the forks param
	tasks=${cores}
	echo -n "${cores},${tasks}," | tee -a ${log1} ${log2}
		
	sed "s/NTASKS/${tasks}/" ${ymlinput} > ${ymlinput}.${tasks}.yml
	sed -i "s/LOG1/host1_tasks${tasks}.txt/" ${ymlinput}.${tasks}.yml 
	sed -i "s/LOG2/host2_tasks${tasks}.txt/" ${ymlinput}.${tasks}.yml
	sed "s/CORES/${cores}/" backend.conf > ${ymlsDir}/backend.conf.${cores}

	##### processes: 1
	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%F,%I,%O,%r,%s,%x" --append --output ${log1} \
	        java -Dconfig.file=${ymlsDir}/backend.conf.${cores} -jar ${crom} run host_process.cwl -i ${ymlinput}.${tasks}.yml --type cwl -o workflow.options.json > ${hostsDir}/host1_tasks${tasks}.txt


	#### Processes: 2
	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%F,%I,%O,%r,%s,%x" --append --output ${log2} \
	        java -Dconfig.file=${ymlsDir}/backend.conf.${cores} -jar ${crom} run host_workflow.cwl -i ${ymlinput}.${tasks}.yml --type cwl -o workflow.options.json > ${hostsDir}/host2_tasks${tasks}.txt

	echo -e "Done processing * ${tasks} * tasks, on * ${cores} * cores" >> ${progress}	
done
echo "##############################################################################################" >> ${progress}

## Aggregating nodes distribution results
cd ${hostsDir}
echo "nodes processes tasks" > ../summarize_hosts_nodes.txt
#for file in `ls -1v`; do   #This assumes output files can be copied directly- not working
#   echo `wc -l $file`| sed 's/_/ /g' >> ../summarize_hosts_nodes.txt 
#done
for file in `ls -1v`; do
	nodes=`grep location $file | cut -d, -f1 | cut -d: -f2 | xargs cat | wc -l`
	echo $nodes $file | sed 's/_/ /g' >> ../summarize_hosts_nodes.txt 
done
	

echo "Bio-Scalability analysis completed for CWL!" | mail -s "WfMS- Bio-Scalability" "azzaea@gmail.com"

