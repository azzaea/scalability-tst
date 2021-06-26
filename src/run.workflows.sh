#!/bin/bash

set -x

iterations=5

srcDir="/home/a-m/azzaea/scalability-tst/src/"
resultsDir="/home/a-m/azzaea/scalability-tst/results/biocluster.2021/"

for (( run=1; run<=${iterations}; run++)); do
	echo "***************** This is run ${run}/${iterations} *********************"
	runResultsDir="${resultsDir}/run${run}/"
	mkdir -p ${runResultsDir}

	cd ${srcDir}/cwl
	sbatch --wait bioinfoScaling.toil.sh
	sbatch --wait bioinfoScaling.cromwell.sh
	mv cwl.* ${runResultsDir}
	mv slurm* ${runResultsDir}

	cd ${srcDir}/wdl
	sbatch --wait bioinfoScaling.cromwell.sh
	mv wdl.* ${runResultsDir}
	mv slurm* ${runResultsDir}

	cd ${srcDir}/nf
	sbatch --wait bioinfoScaling.sh
	mv nf.* ${runResultsDir}
	mv slurm* ${runResultsDir}
done

echo "Bio-Scalability analysis completed for ${iterations} runs" | mail -s "WfMS- Bio-Scalability" "azzaea@gmail.com"

