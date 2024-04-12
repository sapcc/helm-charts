[ml2_arista]
switch_info = {{ range $i, $switch := .Values.arista.switches }}
  {{- $switch.host }}:{{ $switch.user }}:{{ $switch.password | urlquery -}}
  {{- if lt $i (sub (len $.Values.arista.switches) 1) }},{{ end -}}
{{- end }}
