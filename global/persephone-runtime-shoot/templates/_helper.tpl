{{- define "persephone.landscape.short" -}}
{{ required "missing value for .Values.landscapeName" (substr 0 1 .Values.landscapeName) }}
{{- end -}}
