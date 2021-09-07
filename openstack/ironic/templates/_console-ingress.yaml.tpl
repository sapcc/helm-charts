{{- define "ironic_conductor_console_ingress" }}
    {{- $conductor := index . 1 }}
    {{- with index . 0 }}
apiVersion: networking.k8s.io/v1beta1
kind: Ingress

metadata:
  name: ironic-conductor-{{$conductor.name}}-console
  labels:
    system: openstack
    type: api
    component: ironic
  annotations:
    kubernetes.io/tls-acme: "true"
spec:
  tls:
     - secretName: tls-{{ include "ironic_console_endpoint_host_public" . | replace "." "-" }}
       hosts: [{{ include "ironic_console_endpoint_host_public" . }}]
  rules:
    - host: {{ include "ironic_console_endpoint_host_public" . }}
      http:
        paths:
        - path: /{{$conductor.name}}
          backend:
            serviceName: ironic-conductor-{{$conductor.name}}-console
            servicePort: 80
    {{- end }}
{{- end }}
