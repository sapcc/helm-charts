{{- define "nova.cell_secret" }}
{{- $name := index . 1 }}
{{- $transport_url := index . 2 }}
{{- $database_connection := index . 3 }}
{{- with index . 0 }}
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
{{- end }}
