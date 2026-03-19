{{- define "cc-shoots-workerless.clusterRegion" -}}
{{- $clusterName := required "helper argument clusterName is required" .clusterName -}}
{{- $cluster := required (printf "clusters.%s is required" $clusterName) .cluster -}}
{{- required (printf "clusters.%s.region is required" $clusterName) $cluster.region -}}
{{- end -}}

{{- define "cc-shoots-workerless.clusterType" -}}
{{- required "cluster.type is required" .Values.cluster.type -}}
{{- end -}}

{{- define "cc-shoots-workerless.clusterPrefix" -}}
{{- required "cluster.prefix is required" .Values.cluster.prefix -}}
{{- end -}}

{{- define "cc-shoots-workerless.supportGroup" -}}
{{- required "cluster.supportGroup is required" .Values.cluster.supportGroup -}}
{{- end -}}