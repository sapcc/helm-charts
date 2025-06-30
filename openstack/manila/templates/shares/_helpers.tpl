{{- define "filerNameFromHost" -}}
{{- regexSplit "\\.cc" . -1 | first }}
{{- end -}}
