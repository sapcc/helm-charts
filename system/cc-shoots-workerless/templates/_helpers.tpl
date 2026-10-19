{{- define "cc-shoots-workerless.clusterRegion" -}}
{{- $clusterName := required "helper argument clusterName is required" .clusterName -}}
{{- $cluster := required (printf "clusters.%s is required" $clusterName) .cluster -}}
{{- required (printf "clusters.%s.region is required" $clusterName) $cluster.region -}}
{{- end -}}

{{- define "cc-shoots-workerless.clusterType" -}}
{{- required "cluster.type is required" .Values.cluster.type -}}
{{- end -}}

{{- define "cc-shoots-workerless.supportGroup" -}}
{{- required "cluster.supportGroup is required" .Values.cluster.supportGroup -}}
{{- end -}}

{{- define "cc-shoots-workerless.seedName" -}}
{{- $clusterName := required "helper argument clusterName is required" .clusterName -}}
{{- $cluster := required (printf "clusters.%s is required" $clusterName) .cluster -}}
{{- $regionName := required "helper argument regionName is required" .regionName -}}
{{- $seedType := .seedType -}}
{{- if $cluster.seedName -}}
{{- $cluster.seedName -}}
{{- else if eq $seedType "runtime" -}}
{{- printf "rt-%s" $regionName -}}
{{- else -}}
{{- printf "mgmt-%s" $regionName -}}
{{- end -}}
{{- end -}}