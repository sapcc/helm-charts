[default]
{{- range $key, $value := .Values.akamai.edgerc }}
{{$key}} = {{$value}}
{{- end }}
