{{- range $idx, $share := .Values.global.netapp.filers }}
- name: {{ $share.name }}
  host: {{ $share.host }}
  region: {{ required "$.Values.global.region" $.Values.global.region }}
  availability_zone: {{ default $.Values.global.default_availability_zone $share.availability_zone }}
  warning_threshold: {{ default 25 $share.reserved_share_percentage | sub 100 }}
{{- end }}