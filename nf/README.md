# Instructions for creating an AWS cluster:

# install pcluster (or activate if in virtual env)
python3 -m pip install --upgrade pip
pip3 install --user --upgrade virtualenv
virtualenv ~/apc-ve
source ~/apc-ve/bin/activate
pip install --upgrade aws-parallelcluster


```
# configure AWS and the parallel cluster:
aws configure
pcluster configure

# to create AWS slurm cluster:
pcluster create -c pcluster.config aws-slurm-cluster

# ssh by the displayed credentials, then install: java and nextflow

sudo apt install openjdk-8-jre-headless
curl -s https://get.nextflow.io | bash

# clone the scalability repo
git clone https://github.com/azzaea/scalability-tst.git
cd scalability-tst/nf

# test to the joy of your heart! e.g:
nextflow=~/nextflow
${nextflow} run sleep_workflow.nf -profile cluster --ntasks=10 --forks=4 --duration=20 
```
