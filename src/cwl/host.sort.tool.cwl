#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
baseCommand: sort 
arguments: ["-u"]
inputs:
  names1:
    type: File[]
    inputBinding:
      prefix: 
  names2:
    type: File[]?
    inputBinding:
      prefix:

outputs:
  hosts:
    type: stdout
stdout: logfile.txt

