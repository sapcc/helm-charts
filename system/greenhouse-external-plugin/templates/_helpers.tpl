{{- define "external-plugin.hostname" -}}
{{- printf "%s.%s" .Values.namePrefix (required "global.dnsDomain missing" .Values.global.dnsDomain) }}
{{- end }}

{{- define "external-plugin.image" -}}
{{- $repository := required ".Values.image.repository missing" .Values.image.repository -}}
{{- $digest := .Values.image.digest -}}
{{- if $digest -}}
  {{- printf "%s@%s" $repository $digest -}}
{{- else -}}
  {{- printf "%s:%s" $repository (required ".Values.image.tag missing" .Values.image.tag) -}}
{{- end -}}
{{- end -}}
