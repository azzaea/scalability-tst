#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

requirements:
  InlineJavascriptRequirement: {}

baseCommand: echo 

inputs:
  ntimes: int

outputs:
  range:
    type: int[]
    outputBinding:
      outputEval: |-
        ${
          var out = []
          for(var i = 0; i < inputs.ntimes; i++) {
            out.push(i)
          }
          return out
         }
    
#stdout: logfile.txt

