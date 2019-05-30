#!/bin/bash
set -x

sleepDuration=0
log="logs-wdl/times_${sleepDuration}.txt"

echo "ntask,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,exitStatus"> ${log}

export PROCS=16 #Number of processes to use 
export PPN=3 #Number of processes per node
export QUEUE="normal"


while read n; do
	jsonsDir="logs-nf/${sleepDuration}"
	mkdir ${jsonsDir}
	sed "s/ntasks/${n}/" ${json} >	"${jsonsDir}/${json}.${n}"
	echo -n "${n}," >> ${log}
	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log} \
	swift-t -m slurm -O3 strongScaling.swift -duration=${sleepDuration} -ntask=${n}
done < ntasks.txt



