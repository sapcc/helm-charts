collector: Rest
schedule:
  - data: 180s
objects:
  Aggregate: aggr.yaml
  Node: node.yaml
  SVM: svm.yaml
  Status: status.yaml
{{- /*
Extra objects can be defined in values.yaml and added to the list above.
Pass the values, such as (dict "objects" .Values.app.xxx.objects), to the template.
*/}}
  {{- with $.objects }}
  {{- range $object, $file := . }}
  {{ $object }}: {{ $file }}
  {{- end }}
  {{- end }}