{{- range $idx, $share := .Values.netapp.filers }}
- name: {{ $share.name }}
  host: {{ $share.host }}
  username: {{ $share.username }}
  password: {{ $share.password }}
{{- end }}