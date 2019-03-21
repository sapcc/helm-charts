{{- range $idx, $share := .Values.global.netapp.filers }}
- name: {{ $share.name }}
  host: {{ $share.host }}
  username: {{ $share.username }}
  password: {{ $share.password }}
  region: {{ required "$.Values.global.region" $.Values.global.region }}
{{- end }}