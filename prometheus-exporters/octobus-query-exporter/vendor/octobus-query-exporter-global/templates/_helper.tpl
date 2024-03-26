{{- define "config" -}}
header=['Authorization: Apikey {{ required ".Values.octobus.apikey " .Values.octobus.apikey }}']
{{- end -}}
