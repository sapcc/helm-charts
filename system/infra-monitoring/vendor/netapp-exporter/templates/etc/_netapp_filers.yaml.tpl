{{- range $idx, $avzone := .Values.shares  }}
{{- range $idx, $share := .shares_netapp }}
- name: {{ $share.name }}
  host: {{ $share.host }}
  username: {{ $share.username }}
  password: {{ $share.password }}
{{- end }}
{{- end }}