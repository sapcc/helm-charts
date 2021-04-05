{{- range $idx, $share := .Values.global.netapp.filers }}
- name: {{ $share.name }}
  host: {{ $share.host }}
  region: {{ required "$.Values.global.region" $.Values.global.region }}
  availability_zone: {{ $share.availability_zone | default $.Values.global.default_availability_zone }}
  aggregate_pattern: {{ $share.aggregate_search_pattern }}
{{- end }}
