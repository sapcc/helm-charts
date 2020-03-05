{{- define "nova.console_service" }}
{{- $name := index . 1 }}
{{- $config := index . 2 }}
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
  - name: {{ $name }}
    port: {{ $config.portInternal }}
    targetPort: {{ $name }}
{{- end }}
{{- end }}
