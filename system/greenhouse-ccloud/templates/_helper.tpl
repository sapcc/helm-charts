{{/* Thanos store endpoints */}}
{{- define "thanosStoreEndpoints" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $stores := list }}
{{- range $plugin := $root.Values.ingressPlugins -}}
{{- $thanosStore := printf "thanos-grpc.%s:443" (trimSuffix "." (trimPrefix "ingress." $plugin.recordName)) -}}
{{- if contains $name $thanosStore -}}
{{- $stores = append $stores $thanosStore -}}
{{- end -}}
{{- end -}}
{{ range $k, $v := $stores }}
  - {{ $v }}
{{- end }}
{{- end -}}

