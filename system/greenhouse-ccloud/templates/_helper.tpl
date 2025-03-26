{{/* Get store endpoints to put into global queries */}}
{{- define "thanos.storeEndpoints" -}}
{{- range $cluster := $.Values.thanos.globalClusters -}}
{{- $stores := (include "thanos.getRelatedStoreEndpoints" (list $cluster.prefixes $)) }}
{{- if $stores }}
- clusterName: {{ $cluster.name }}
  overrides:
  - name: thanos.query.stores
    value:
      {{- $stores | nindent 8 }}
{{- end }}
{{- end }}
{{- end }}

{{/* Get related Thanos store endpoints filtered by given prefix */}}
{{- define "thanos.getRelatedStoreEndpoints" -}}
{{- $prefixes := index . 0 -}}
{{- $root := index . 1 -}}
{{- $stores := list }}
{{- range $plugin := $root.Values.ingressPlugins -}}
{{- range $prefix := $prefixes -}}
{{- if and (hasPrefix "ingress" $plugin.recordName ) (hasSuffix "." $plugin.recordName ) }}
{{- $thanosStore := printf "thanos-grpc.%s:443" (trimSuffix "." (trimPrefix "ingress." $plugin.recordName)) -}}
{{- if contains $prefix $thanosStore -}}
{{- $stores = append $stores $thanosStore -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{ range $k, $v := $stores }}
  - {{ $v }}
{{- end }}
{{- end -}}
