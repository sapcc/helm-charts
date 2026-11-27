{{- if .Values.allow_transfer }}
allow-transfer { {{ range $tsig := .Values.allow_transfer.tsig }} key "{{ $tsig.keyname }}"; {{ end }} };
{{- else }}
allow-transfer { none; };
{{- end }}
