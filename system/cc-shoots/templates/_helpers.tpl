{{- define "cc-shoots.clusterType" -}}
{{- required "cluster.type is required" .Values.cluster.type -}}
{{- end -}}
