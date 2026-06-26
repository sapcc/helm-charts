{{- define "nova.cell_conf" }}
{{- $envAll := index . 0 }}
{{- $cellId := index . 1 }}
{{- if ne $cellId "cell0" -}}
[DEFAULT]
transport_url = {{ include "nova.helpers.cell_rabbitmq_url" (tuple $envAll $cellId) }}

{{ end -}}
[database]
connection = {{ include "nova.helpers.db_url" (tuple $envAll $cellId) }}
{{ end }}
