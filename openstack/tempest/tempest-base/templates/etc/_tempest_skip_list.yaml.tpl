{{- define "tempest-base.skip_list" }}
{{- if .mySkipList }}
{{- range $test, $reason := .mySkipList }}
{{ $test }}: {{ $reason | quote }}
{{- end -}}
{{- end -}}
{{ end }}