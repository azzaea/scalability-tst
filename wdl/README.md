To do anything in wdl:

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


