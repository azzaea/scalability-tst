#!/bin/bash
set -x

sleepDuration=0
log="logs-wdl/times_${sleepDuration}.txt"
json="logs-wdl/strongScaling_${sleepDuration}.json"

sed "s/SleepDuration/${sleepDuration}/" strongScaling.tmpl > ${json}

echo "ntask,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,exitStatus"> ${log}

while read n; do
	jsonsDir="logs-nf/${sleepDuration}"
	mkdir ${jsonsDir}
	sed "s/ntasks/${n}/" ${json} >	"${jsonsDir}/${json}.${n}"
	echo -n "${n}," >> ${log}
#	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%x" --append --output ${log} \
#		java -Dconfig.file=slurm.config -jar /home/a-m/azzaea/software/wdl/cromwell-39.jar run strongScaling.wdl -i ${jsonsDir}/${json}.${n}
done < ntasks.txt



