#!/bin/bash

cd hosts
echo "nodes processes tasks"
for file in `ls -1v`
do
    nodes=`grep hostwf.logfil $file | sed '2d' | cut -d: -f2 | xargs cat | wc -l`
    echo $nodes $file | sed 's/_/ /g'
done
