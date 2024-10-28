{{- define "ironic_conductor_console_service" }}
    {{- $conductor := index . 1 }}
    {{- with index . 0 }}
kind: Service
apiVersion: v1

metadata:
{{- if $conductor.name }}
  name: ironic-conductor-{{$conductor.name}}-console
{{- else }}
  name: ironic-conductor-console
{{- end }}
  labels:
    system: openstack
    type: api
    component: ironic-conductor
  annotations:
    {{- include "utils.linkerd.pod_and_service_annotation" . | indent 4 }}
spec:
  selector:
  {{- if $conductor.name }}
    name: ironic-conductor-{{$conductor.name}}
  {{- else }}
    name: ironic-conductor
  {{- end }}
  ports:
  - name: ironic-console
    port: 443
    {{- end }}
{{- end }}
