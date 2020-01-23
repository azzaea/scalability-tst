~~At present, I posted to [discourse](https://cwl.discourse.group/t/scatter-a-specific-number-of-times/71) for how to automatically loop a set number of times- otherwise, I may need to do it manually.~~
There is no direct way to specify a loop limit in cwl. One has to manually set up an echo step that enumerates through the range using InLineJavaExpression _(problem solved this way)_

Next, I will test running the `host_process.cwl` and `host_workflow.cwl` scripts via both: 
- cromwell. Using the command:
```
java -jar -Dconfig.file=backend.conf $crom run host_process.cwl -i host.workflow.yml --type cwl -o workflow.options.json
```
- toil: Using the command:
```
module load Python/2.7.13-IGB-gcc-4.9.4
export TOIL_SLURM_ARGS="-p normal"
toil-cwl-runner host_process.cwl host.workflow.yml #--batchSystem Slurm --out_dir outputDirectory myjobstore
```

After that, I will be left with writing the script that automates the testing loop and gathers the results.

To run these tests in my computer, I need the `cwl-runner`. It is avaialble via a python `virtualenv`


```
source ~/pythonenvs/cwlref/bin/activate

cwl-runner <cwl script> <cwl yml options>

```
