mappings:
- match: netapp.perf.*.*.node.*.*.*
  name: netapp_perf_node
  labels:
    Group: $1
    Cluster: $2
    Node: $3
    Tag: $4
    Metric: $5
- match: netapp.perf.*.*.svm.*.*.*
  name: netapp_perf_svm
  labels:
    Group: $1
    Cluster: $2
    VServer: $3
    Tag: $4
    Metric: $5
- match: netapp.perf.*.*.svm.*.vol.*.*
  name: "netapp_volume_${5}"
  labels:
    group: $1
    filer: $2
    vserver: $3
    volume: $4
- match: netapp.perf.*.*.svm.*.*.*.*
  name: netapp_perf_svm
  labels:
    Group: $1
    Cluster: $2
    VServer: $3
    LabelName: $4
    LabelValue: $5
    Metric: $6
- match: netapp.perf.*.*.svm.*.*.*.*.*
  name: netapp_perf_svm
  labels:
    Group: $1
    Cluster: $2
    VServer: $3
    LabelName: $4
    LabelValue: $5
    Tag: $6
    Metric: $7
- match: netapp.perf.*.*.svm.*.*.*.*.*.*
  name: netapp_perf_svm
  labels:
    Group: $1
    Cluster: $2
    VServer: $3
    LabelName: $4
    LabelValue: $5
    SubLabelType: $6
    SubLabelValue: $7
    Metric: $8
- match: .
  match_type: regex
  action: drop
  name: dropped
