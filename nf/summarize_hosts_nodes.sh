#!/bin/bash
cd hosts
echo "nodes processes tasks"
for file in `ls -1v`
do
    echo `wc -l $file`| sed 's/_/ /g'
done
