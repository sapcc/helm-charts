{{- range $name, $container := .Values.sftp.logins }}
{{ $name }}:{{ $container }}
{{- end }}
