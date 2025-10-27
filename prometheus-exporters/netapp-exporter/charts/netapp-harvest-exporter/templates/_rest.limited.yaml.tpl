collector: Rest
schedule:
  - data: 180s
objects:
  Aggregate: aggr.yaml
  Node: node.yaml
  SVM: svm.yaml
  Status: status.yaml
{{- /*
  Add extra items to this object list.
*/}}
  {{- with $.objects }}
  {{- range $object, $file := . }}
  {{ $object }}: {{ $file }}
  {{- end }}
  {{- end }}
