#!bin/bash

# ssh by the displayed credentials 

# Clone the scalability repo
git clone https://github.com/azzaea/scalability-tst.git

# Install needed software (and document versions)
mkdir software
cd software
versionslog="tools.versions.log"

# nextflow
sudo apt install openjdk-8-jre-headless
curl -s https://get.nextflow.io | bash

./nextflow -v > $versionslog

# cromwell
wget https://github.com/broadinstitute/cromwell/releases/download/42/cromwell-42.jar

java -jar cromwell-42.jar --version >> $versionslog 




