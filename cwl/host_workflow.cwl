class: Workflow
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
inputs:
  - id: ntasks
    type: int
    'sbg:x': 0
    'sbg:y': 53.5
outputs:
  - id: result
    outputSource:
      - catHostsTask/hosts
    type: File
    'sbg:x': 665.40625
    'sbg:y': 94.5
steps:
  - id: catHostsTask
    in:
      - id: names1
        linkMerge: merge_flattened
        source:
          - host1/result
          - host2/result
    out:
      - id: hosts
    run: host.sort.tool.cwl
    'sbg:x': 522.71875
    'sbg:y': 92
  - id: host1
    in:
      - id: iteration
        source: Iterator/range
    out:
      - id: result
    run: host.hostname.tool.cwl
    scatter:
      - iteration
    'sbg:x': 282.03125
    'sbg:y': 53.5
  - id: host2
    in:
      - id: iteration
        source: host1/result
    out:
      - id: result
    run: host.hostname.tool.cwl
    scatter:
      - iteration
    'sbg:x': 450.71875
    'sbg:y': 0
  - id: Iterator
    in:
      - id: ntimes
        source: ntasks
    out:
      - id: range
    run: host.serialize.tool.cwl
    'sbg:x': 119.671875
    'sbg:y': 53.5
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement
'sbg:toolAuthor': Azza E Ahmed
