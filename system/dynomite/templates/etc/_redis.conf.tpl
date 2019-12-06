{{- $context := index . 0 -}}
{{- $member := index . 1 -}}
{{- $index := index . 2 -}}
port 22122
{{- if $context.Values.debug }}
loglevel debug
{{- end }}
replica-announce-ip {{ $member | include "dynomite.ip" }}
