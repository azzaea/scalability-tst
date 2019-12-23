#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

requirements:
  ScatterFeatureRequirement: {}
  MultipleInputFeatureRequirement: {} #Is it supported by wfms?

inputs:
  iter: int 

outputs:  
  result:
    type: File
    outputSource: catsortStep/hosts

steps:
  rangeStep:
    run: host.serialize.tool.cwl
    in:
      ntimes: iter
    out: [range]
  hostStep1:
    run: host.hostname.tool.cwl 
    scatter: iteration 
    in:
      iteration: rangeStep/range
    out: [result]
  hostStep2:
    run: host.hostname.tool.cwl 
    scatter: iteration 
    in:
      iteration: hostStep1/result 
    out: [result]
  catsortStep:
    run: host.sort.tool.cwl
    in:
      names1:
        source: [hostStep1/result, hostStep2/result] #If supported,
        linkMerge: merge_flattened #great. Else, remove those lines
      #names1: hostStep1/result    #& the requirement, and uncomment
      #names2: hostStep2/result    #these- optional vs merged inputs)
    out: [hosts]

