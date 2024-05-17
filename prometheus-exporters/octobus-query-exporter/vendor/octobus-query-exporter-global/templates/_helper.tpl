{{- define "config-global" -}}
header=['Authorization: Apikey {{ required ".Values.octobus.apikey " .Values.octobus.apikey }}']
{{- end -}}
