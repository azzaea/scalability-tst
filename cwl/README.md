~~At present, I posted to [discourse](https://cwl.discourse.group/t/scatter-a-specific-number-of-times/71) for how to automatically loop a set number of times- otherwise, I may need to do it manually.~~
Actually, the cwl scripts: `host_process.cwl` and `host_workflow.cwl` are both now ready for deployment :)

Next, I will test running the `host_process.cwl` and `host_workflow.cwl` scripts via both: 
- cromwell
- toil

After that, I will be left with writing the script that automates the testing loop and gathers the results.

To run these tests in my computer, I need the `cwl-runner`. It is avaialble via a python `virtualenv`


```
source ~/pythonenvs/cwlref/bin/activate

cwl-runner <cwl script> <cwl yml options>

```
