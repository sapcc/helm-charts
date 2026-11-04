[uwsgi]
{{- if not (hasKey .Values.uwsgi "http-socket") }}
http-socket = :{{ .Values.global.placementApiPortInternal }}
{{- end }}
{{- range $key := keys .Values.uwsgi | sortAlpha }}
{{- $value := index $.Values.uwsgi $key }}
{{- if and (ne $value nil) (ne (toString $value) "") }}
{{ $key }} = {{ $value }}
{{- end }}
{{- end }}

