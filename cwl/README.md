At present, I posted to [discourse](https://cwl.discourse.group/t/scatter-a-specific-number-of-times/71) for how to automatically loop a set number of times- otherwise, I may need to do it manually.

Also, next, I will test running the `host_process.cwl` and `host_workflow.cwl` scripts via both: 
- cromwell
- toil

Finally, I will be left with writing the script that automates the testing loop and gathers the results.

To run these tests in my computer, I need the `cwl-runner`. It is avaialble via a python `virtualenv`


```
source ~/pythonenvs/cwlref/bin/activate

cwl-runner <cwl script> <cwl yml options>

```
