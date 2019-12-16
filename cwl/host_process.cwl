#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

requirements:
  ScatterFeatureRequirement: {}

inputs:
  iter: int[] 

outputs:  
  result:
    type: File
    outputSource: catsortStep/hosts

steps:
  hostStep1:
    run: host.hostname.tool.cwl 
    scatter: iteration 
    in:
      iteration: iter
    out: [result]
  catsortStep:
    run: host.sort.tool.cwl
    in:
      names1: hostStep1/result
    out: [hosts]



