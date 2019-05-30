#!/bin/bash

sleepDuration=0
log="logs-nf/times_${sleepDuration}.txt"

echo "ntask,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,exitStatus"> ${log}
while read n; do
	echo -n "${n}," >> ${log}
	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log} \
		~/software/nextflow/19.04.1 run strongScaling.nf -profile cluster --ntasks=${n} --duration=${sleepDuration}
done < ntasks.txt


