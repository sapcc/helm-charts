Defaults:
  username: {{ .Values.global.netapp_exporter_user }}
  password: {{"{{"}} resolve "{{ .Values.global.netapp_exporter_password }}" {{"}}"}}
