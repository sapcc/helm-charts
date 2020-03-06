{{- define "dynomite.image" -}}
  {{- if typeIs "string" $.Values.dynomite.image.tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .Values.dynomite.image.tag -}}
      {{ .Values.global.registry }}/{{ .Values.dynomite.image.repository }}:{{ .Values.dynomite.image.tag | printf "%0.f" }}
    {{- else -}}
      {{ .Values.global.registry }}/{{ .Values.dynomite.image.repository }}:{{ .Values.dynomite.image.tag }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "redis.image" -}}
{{- required ".Values.redis.image.repository missing" .Values.redis.image.repository -}}:{{- required ".Values.redis.image.tag missing" .Values.redis.image.tag -}}
{{- end -}}

{{- define "dynomite.ip" -}}
{{ (split ":" .)._0 }}
{{- end -}}

{{- define "dynomite.port" -}}
{{ (split ":" .)._1 }}
{{- end -}}

{{- define "dynomite.rack" -}}
{{ (split ":" .)._2 }}
{{- end -}}

{{- define "dynomite.dc" -}}
{{ (split ":" .)._3 }}
{{- end -}}

{{- define "dynomite.token" -}}
{{ (split ":" .)._4 }}
{{- end -}}

{{- define "dynomite.token_peers" -}}
{{- $member := index . 0 -}}
{{- $foreign_member := index . 1 -}}
{{- $token := $member | include "dynomite.token" -}}
{{- $peers := list -}}
{{- range $foreign_member -}}
  {{- $current_token := . | include "dynomite.token" -}}
  {{- if eq $token $current_token -}}
    {{- $current_ip := . | include "dynomite.ip" -}}
    {{- $peers = append $peers $current_ip -}}
  {{- end -}}
{{- end -}}
{{ first $peers }}
{{- end -}}
