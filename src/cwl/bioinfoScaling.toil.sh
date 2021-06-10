#!/bin/bash
#SBATCH --mail-user azzaea@gmail.com
#SBATCH --mail-type BEGIN,END,FAIL

module load toil # for biocluster
module load nodejs # for biocluster

echo "Analysis done on: "
date

export TOIL_SLURM_ARGS="-p normal" # for biocluster

set -x

#############################################################################################
#### For bioinfo scalability: scalability scenarios meaningful in the context of bioinformatics.
#### Part I: Allocate 1 node, and benchmark time for tasks=1:#cores in this node
#### Part II: Increase the number of nodes in the cluster gradually (i.e. increase the number of
#### tasks by the number of cores in a node, and benchmark. 
#### This script reads values for cores from a file: cores.txt in the same directory
##############################################################################################

resultsDir="cwl.toil"
logsDir="${resultsDir}/logs"
ymlsDir="${logsDir}/ymls"
hostsDir=" ${resultsDir}/hosts"
workDir="toil-executions"
mkdir -p ${resultsDir} ${logsDir} ${ymlsDir} ${hostsDir} 
mkdir ${workDir} # toil-cwl-runner can't automatically create the working directory of a run, 
           # but requires it be specified when working in cluster environments

progress="${logsDir}/progress_bioinfoScaling.txt"
echo "Starting BioInfo Scalability Analysis" >> ${progress}
echo "#############################################################################" >> ${progress} 
toil --version >> ${progress}
echo "##############################################################################" >> ${progress} 

ifstat -t -T -n -w > ${logsDir}/network-report.txt

log1="${logsDir}/bioinfoScaling_processes-1_host.txt"
log2="${logsDir}/bioinfoScaling_processes-2_host.txt"
echo "cores,tasks,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,faults,inputs,outputs,socketsIn,socketsOut,exitStatus" | tee -a ${log1} ${log2}
ymlinput="${ymlsDir}/host_process_workflow"
cat host_process_workflow.yml.tmpl > ${ymlinput}

for line in {1..10}; do # Enough until 512 tasks in biocluster
	cores=`cat cores.txt | sed -n ${line}p` 
	tasks=${cores}
	echo -n "${cores},${tasks}," | tee -a ${log1} ${log2}
		
	sed "s/NTASKS/${tasks}/" ${ymlinput} > ${ymlinput}.${tasks}.yml
	sed -i "s/LOG1/host1_tasks${tasks}.txt/" ${ymlinput}.${tasks}.yml 
	sed -i "s/LOG2/host2_tasks${tasks}.txt/" ${ymlinput}.${tasks}.yml

	##### processes: 1
	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%F,%I,%O,%r,%s,%x" --append --output ${log1} \
		toil-cwl-runner --jobStore myStore --batchSystem slurm --outdir ${hostsDir} --workDir ${workDir} --maxCores ${cores} --disableCaching true  host_process.cwl ${ymlinput}.${tasks}.yml
		toil clean myStore # for just in case a job fails within the loop

	#### Processes: 2 
	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%F,%I,%O,%r,%s,%x" --append --output ${log2} \
	        toil-cwl-runner --jobStore myStore --batchSystem slurm --outdir ${hostsDir} --workDir ${workDir} --maxCores ${cores} --disableCaching true host_workflow.cwl ${ymlinput}.${tasks}.yml 
		toil clean myStore # for just in case a job fails within the loop

	echo -e "Done processing * ${tasks} * tasks, on * ${cores} * cores" >> ${progress}	
done
echo "##############################################################################################" >> ${progress}


## Aggregating nodes distribution results
cd ${hostsDir}
echo "nodes processes tasks" > ../summarize_hosts_nodes.txt
for file in `ls -1v`; do
   echo `wc -l $file`| sed 's/_/ /g' >> ../summarize_hosts_nodes.txt 
done

echo "Bio-Scalability analysis completed for CWL!" | mail -s "WfMS- Bio-Scalability" "azzaea@gmail.com"




