{{- if .Values.tempest.expected_failures }}
{{- range $test, $reason := .Values.tempest.expected_failures }}
{{ $test }}: {{ $reason | quote }}
{{- end -}}
{{- end -}}
