mappings: 
- match: netapp.perf.*.*.node.*.*.*
  name: netapp_perf_node
  labels: 
    Group: $1
    Cluster: $2
    Node: $3
    Set: $4
    Metric: $5
- match: netapp.perf.*.*.svm.*.*.*
  name: netapp_perf_svm
  labels:
    Group: $1
    Cluster: $2
    SVM: $3
    Set: $4
    Metric: $5
- match: netapp.perf.*.*.svm.*.*.*.*
  name: netapp_perf_svm
  labels:
    Group: $1
    Cluster: $2
    SVM: $3
    Type: $4
    TypeValue: $5
    Metric: $6
- match: netapp.perf.*.*.svm.*.*.*.*.*
  name: netapp_perf_svm
  labels:
    Group: $1
    Cluster: $2
    SVM: $3
    Type: $4
    TypeValue: $5
    Set: $6
    Metric: $7
- match: netapp.perf.*.*.svm.*.*.*.*.*.*
  name: netapp_perf_svm
  labels:
    Group: $1
    Cluster: $2
    SVM: $3
    Type: $4
    TypeValue: $5
    SubType: $6
    SubTypeValue: $7
    Metric: $8
- match: .
  match_type: regex
  action: drop
  name: dropped

