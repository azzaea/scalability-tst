#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

baseCommand: hostname

stdout: result.host.txt

inputs: 
  iteration: 
    type: 
      - int
      - File 

outputs: 
  result:
    type: stdout
