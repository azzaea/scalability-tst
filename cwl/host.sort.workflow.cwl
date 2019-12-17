class: Workflow
cwlVersion: v1.0

requirements:
  MultipleInputFeatureRequirement: {}

inputs:
  names1: File[]
  names2: File[]

outputs:
  result:
    type: File
    outputSource: step1/hosts

steps: 

  step1:
    run: host.sort.tool.cwl
    in:
      names1: 
        source: [names1, names2]
        linkMerge: merge_flattened
    out: [hosts]
