
The files in this directory are the scripts and configs needed for testing the scalability of running [CWL]() code via:
1. _Cromwell_: has cluster support (`bioinfoScaling.cromwell.sh`)
2. _Toil_: also has cluster support (only partial code, not tested: `bioinfoScaling.toil.sh`)

As such, the code is written in CWL v1.0
We used a 1- and 2- process workflow scattered across n tasks, where n is increased gradually; at a rate of 1 process/cpu.

<p align="center">
  <img src="dag_cwl_rabix_hosts_workflow.png" width =450>
</p>

**Fig.** The 2-process workflow DAG (via `rabix` GUI)


## Visualizing the dag:

The DAG of CWL scripts can be visualized vi either the [CWLViewer](https://view.commonwl.org/) app page, or via `rabix` directly 

## Running CWL code:

### Cromwell

The main commands to run via cromwell are below:

```
$ sed "s/CORES/2/" backend.conf > backend.conf.2 # This sets the rate of new jobs/sec. Remember to check for your backend specifics (eg queue)
$
$ java -jar -Dconfig.file=backend.conf.2 $crom run host_process.cwl -i host.workflow.yml --type cwl #-o workflow.options.json # The "options" flag is not recognized
$
$ java -jar -Dconfig.file=backend.conf.2 $crom run host_workflow.cwl -i host.workflow.yml --type cwl #-o workflow.options.json # The "options flag is not recognized"
$
$ rm backend.conf.2 # the file not really needed anymore
```


### Toil

```
$ resultsDir="results.toil.cwl"
$ hostsDir="${resultsDir}/hosts"
$ mkdir -p ${resultsDir} ${hostsDir}

$ module load toil
$ module load nodejs 
$ export TOIL_SLURM_ARGS="-p normal"
$ mkdir work # create working directory. Wouldn't work if not already existing
$ toil-cwl-runner --jobStore myStore \
--batchSystem Slurm \
--outdir ${hostsDir}  \# output directory
--workDir work \# this must always be present, and direct to an existing directory
--stats \# generates nice stats at the end via `toil stats file:myStore`
--logFile cwltoil.log --logLevel DEBUG --cleanWorkDir never \# useful for debugging - may remove all for actual deployment
host_process.cwl host_process_workflow.yml

```

- we try to run all workflows with the same options- eg, all with specified results directory. With toil it appears we also need to spcify where to keep tmp files (others did it automatically)

- Important: For this workflow, toil also needed node.js engine to be accessible. On biocluster, I run into conflicts when loading `nodejs` and `Python`, hence I have not been able to run this `host*` workflows there yet. In other words, the requirements of cwl need to be supported. For example, a `CommandLineTool` with:

```
requirements:
  InlineJavascriptRequirement: {}
```

  when invoked with toil gives an error: `cwltool requires Node.js engine to evaluate and validate Javascript expressions, but couldn't find it.  Tried nodejs, node, docker run node:slim`.  With cromwell, this error did not come up

- Relevant options to request resources are below. I think we only need to control the first in this list. Check via the `toil stats` command

    * `--maxCores INT`        
                        The maximum number of CPU cores to request from the
                        batch system at any one time. Standard suffixes like
                        K, Ki, M, Mi, G or Gi are supported. Default is 8.0 Ei

    * `--maxLocalJobs MAXLOCALJOBS`
                        For batch systems that support a local queue for 
                        housekeeping jobs (Mesos, GridEngine, htcondor, lsf,
                        slurm, torque), the maximum number of these
                        housekeeping jobs to run on the local system. The
                        default (equal to the number of cores) is a maximum of
                        16 concurrent local housekeeping jobs.
                        
    * `--runCwlInternalJobsOnWorkers`
                        Whether to run CWL internal jobs (e.g. CWLScatter) on
                        the worker nodes instead of the primary node. If false
                        (default), then all such jobs are run on the primary
                        node. Setting this to true can speed up the pipeline
                        for very large workflows with many sub-workflows 
                        and/or scatters, provided that the worker pool is
                        large enough.
 
     * `--defaultCores FLOAT`
                         The default number of CPU cores to dedicate a job.
                        Only applicable to jobs that do not specify an
                        explicit value for this requirement. Fractions of a
                        core (for example 0.1) are supported on some batch
                        systems, namely Mesos and singleMachine. Default is
                        1.0


## Acknowledgement

I like to acknowledge [Kaushik Ghose](https://github.com/kaushik-work) from the cWL community for help implementing the scatter trick via [discourse](https://cwl.discourse.group/t/scatter-workflow-step-n-times/71/4)

# Feb 2020
I only need to aggregate toil tests for scalability now!

