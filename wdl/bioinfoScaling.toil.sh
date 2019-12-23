#!/bin/bash

analysisDir=`pwd`
echo ${analysisDir}
## Prepare toil environment- generic set up:
cd  ~/software/
#git clone https://github.com/azzaea/toil.git
cd toil
#srun --pty /bin/bash  #On biocluster, set up can't be on the login node!

module load Python/2.7.13-IGB-gcc-4.9.4                              #Biocluster specific
python setup.py build
export PYTHONPATH=/home/a-m/azzaea/toil/lib/python2.7/site-packages/ #Biocluster specific
python setup.py install --prefix=/home/a-m/azzaea/toil               #Biocluster specific

export TOIL_SLURM_ARGS="-p normal"                                   #Biocluster specific

cd ${analysisDir}
set -x
##############################################################################################
#### For bioinfo scalability: scalability scenarios meaningful in the context of bioinformatics.
#### Part I: Allocate 1 node, and benchmark time for tasks=1:#cores in this node
#### Part II: Increase the number of nodes in the cluster gradually (i.e. increase the number of
#### tasks by the number of cores in a node, and benchmark. 
#### This script reads values for cores from a file: cores.txt in the same directory
##############################################################################################

resultsDir="results.toil"
jsonsDir="${resultsDir}/logs-wdl/jsons"
hostsDir=" ${resultsDir}/hosts"
mkdir -p ${resultsDir} ${jsonsDir} ${hostsDir}

progress="${resultsDir}/logs-wdl/progress_bioinfoScaling.txt"
echo "Starting BioInfo Scalability Analysis" >> ${progress}
echo "#############################################################################" >> ${progress} 
toil --version >> ${progress}
echo "##############################################################################" >> ${progress} 

ifstat -t -T -n -w > ${resultsDir}/logs-wdl/network-report.txt

log1="${resultsDir}/logs-wdl/bioinfoScaling_processes-1_host.txt"
echo "cores,tasks,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,faults,inputs,outputs,socketsIn,socketsOut,exitStatus" | tee -a ${log1} 
jsoninput="${jsonsDir}/host_process_workflow"
cat host_process_workflow.json.tmpl > ${jsoninput}

for line in {1..15}; do
	cores=`cat cores.txt | sed -n ${line}p`  #goes to the forks param
	tasks=${cores}
	echo -n "${cores},${tasks}," | tee -a ${log1} 
		
	sed "s/NTASKS/${tasks}/" ${jsoninput} > ${jsoninput}.${tasks}.json
	sed -i "s/LOG1/host1_tasks${tasks}.txt/" ${jsoninput}.${tasks}.json 
	sed -i "s/LOG2/host2_tasks${tasks}.txt/" ${jsoninput}.${tasks}.json
	#sed "s/CORES/${cores}/" backend.conf > ${jsonsDir}/backend.conf.${cores}

	##### processes: 1
	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%F,%I,%O,%r,%s,%x" --append --output ${log1} \
		toil-wdl-runner host_process.wdl ${jsoninput}.${tasks}.json --batchSystem Slurm --out_dir ${hostsDir} myjobstore

	#### Processes: 2 (Does not work in toil!)
	#/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%F,%I,%O,%r,%s,%x" --append --output ${log2} \
	        #java -Dconfig.file=${jsonsDir}/backend.conf.${cores} -jar ${crom} run host_workflow.wdl -i ${jsoninput}.${tasks}.json -o workflow.options.json 

	echo -e "Done processing * ${tasks} * tasks, on * ${cores} * cores" >> ${progress}	
done
echo "##############################################################################################" >> ${progress}


## Aggregating nodes distribution results
cd ${hostsDir}
echo "nodes processes tasks"
for file in `ls -1v`
do
   echo `wc -l $file`| sed 's/_/ /g' >> ../summarize_hosts_nodes.txt 
done

echo "Bio-Scalability analysis completed for WDL!" | mail -s "WfMS- Bio-Scalability" "azzaea@gmail.com"

