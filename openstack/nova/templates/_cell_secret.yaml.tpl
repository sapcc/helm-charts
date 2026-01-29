{{- define "nova.cell_secret" }}
{{- $envAll := index . 0 }}
{{- $cellId := index . 1 }}
{{- $name := include "nova.helpers.cell_name" (tuple $envAll $cellId) }}
{{- $transport_url := include "nova.helpers.cell_rabbitmq_url" (tuple $envAll $cellId) }}
{{- $database_connection := include "nova.helpers.db_url" (tuple $envAll $cellId) }}
apiVersion: v1
kind: Secret
metadata:
  name: nova-cell-{{ $name }}
  labels:
    system: openstack
    type: nova-cell
    component: nova
type: Opaque
data:
  name: {{ $name | b64enc }}
  database_connection: {{ $database_connection | b64enc }}
  transport_url: {{ $transport_url | b64enc }}
{{- end }}
