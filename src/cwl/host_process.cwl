#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

requirements:
  ScatterFeatureRequirement: {}

inputs:
  ntasks: int 
  logfile1: string

outputs:  
  result:
    type: File
    outputSource: catsortStep/hosts

steps:
  rangeStep:
    run: host.serialize.tool.cwl
    in:
      ntimes: ntasks
    out: [range]
  hostStep1:
    run: host.hostname.tool.cwl 
    scatter: iteration 
    in:
      iteration: rangeStep/range
    out: [result]
  catsortStep:
    run: host.sort.tool.cwl
    in:
      names1: hostStep1/result
      logfile: logfile1
    out: [hosts]



