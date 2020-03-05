{{- define "tempest-base.expected_failures" }}
{{- if .myXfails }}
{{- range $test, $reason := .myXfails }}
{{ $test }}: {{ $reason | quote }}
{{- end -}}
{{- end -}}
{{ end }}