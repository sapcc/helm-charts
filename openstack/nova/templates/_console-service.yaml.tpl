{{- define "nova.console_service" }}
{{- $name := index . 1 }}
{{- $type := index . 2 }}
{{- $config := index . 3 }}
{{- with index . 0 }}
kind: Service
apiVersion: v1
metadata:
  name: nova-console-{{ $name }}
  labels:
    system: openstack
    type: backend
    component: nova
spec:
  selector:
    name: nova-console-{{ $name }}
  ports:
  - name: {{ $type }}
    port: {{ $config.portInternal }}
    targetPort: {{ $type }}
{{- end }}
{{- end }}
