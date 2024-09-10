{{- define "config" -}}
header=['Authorization: Apikey {{ required ".Values.global.octobus.apikey" .Values.global.octobus.apikey }}']
{{- end -}}
