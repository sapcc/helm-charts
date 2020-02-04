{{- define "dynomite.image" -}}
{{- required ".Values.dynomite.image.repository missing" .Values.dynomite.image.repository -}}:{{- required ".Values.dynomite.image.tag missing" .Values.dynomite.image.tag -}}
{{- end -}}

{{- define "redis.image" -}}
{{- required ".Values.redis.image.repository missing" .Values.redis.image.repository -}}:{{- required ".Values.redis.image.tag missing" .Values.redis.image.tag -}}
{{- end -}}

{{- define "backup.image" -}}
{{- required ".Values.backup.image.repository missing" .Values.backup.image.repository -}}:{{- required ".Values.backup.image.tag missing" .Values.backup.image.tag -}}
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
