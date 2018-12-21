{{- if .Values.tempest.skip_list }}
{{- range $test, $reason := .Values.tempest.skip_list }}
{{ $test }}: {{ $reason | quote }}
{{- end -}}
{{- end -}}
