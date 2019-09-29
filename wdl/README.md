To do anything in wdl:

## Sep 29 update
I have updated the host_process and host_workflow wdl scripts so they can produce an output file in the `hosts` directory (by invoking the workflow.options as follows:
```
java -jar $crom run host_workflow.wdl -i host_process_workflow.json -o workflow.options.json
```

I should next update the corresponding bash scripts for scalability, and also for summarizing the results (this will be the same as the nextflow script, but will take it later)

This new code works with cromwell. Toil process the `host_process.wdl` script, but generates an error with the `host_workflow.wdl` version (apparanetly, a limitation in the scatter: where for some reason, a cascade between processes is not expected. Below is an example invocation:

```
toil-wdl-runner host_workflow.wdl host_process_workflow.json # does not work- scatter problem
toil-wdl-runner host_process.wdl host_process_workflow.json
```




##

I'm running the analysis in WDL-2 so that I can use both cromwell and toil and compare them

```
# Define path of cromwell and womtool
$ crom=
$ wom=
# Check the validity of code, and generate inputs template:
# THIS IS A REMINDER ONLY. DO NOT DO IT FOR EXISTING CODE. 
# EXISTING SCALABILITY SCRIPTS REPLACE CERTAIN VALUES IN THE 
# TEMPLATE
# $ java -jar $wom inputs sleep_process.wdl > sleep_process.json.tmpl
# ALWAYS Copy the json.tmpl file and provide inputs as you desire

# Execute the workflow
$ java -jar $crom run sleep_workflow.wdl -i sleep_workflow.json
```

To generate the DAG (and assuming the Graphviz tool is installed)
```
$ java -jar $wom <graph|womgraph> sleep_workflow.wdl > sleep_workflow_dag.dot #simple or detailed graph
$ dot -Tps sleep_workflow_dag.dot -o sleep_workflow_dag.dot.ps
```

Now, let's move to the scalability scripts. Simply create a cluster [as you did for nf], then install cromwell:
```
$ mkdir -p software/wdl
$ cd software/wdl
$ wget https://github.com/broadinstitute/cromwell/releases/download/42/cromwell-42.jar
# Define the cromwell jar
$ crom=~/software/wdl/cromwell-42.jar
```
Now, run the strong and weak scalability scripts to your amusement!


# View the dag:

```
java -jar $wom womgraph host_workflow.wdl > dag_wdl_hosts_workflow_detailed.dot # Detailed dag

java -jar $wom graph host_workflow.wdl > dag_wdl_hosts_workflow_detailed.dot # Simple dag
dot -Tpng dag_wdl_hosts_workflow_detailed.dot -o dag_wdl_hosts_workflow_detailed.png
```

Instead, I could easily have used [Pipeline Builder](http://pb.opensource.epam.com/)
