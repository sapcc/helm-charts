{{- define "ironic_conductor_console_ingress" }}
    {{- $conductor := index . 1 }}
    {{- with index . 0 }}
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
{{- if $conductor.name }}
  name: ironic-conductor-{{$conductor.name}}-console
{{- else }}
  name: ironic-conductor-console
{{- end }}
  labels:
    system: openstack
    type: api
    component: ironic
  annotations:
    kubernetes.io/tls-acme: "true"
    ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    {{- include "utils.linkerd.ingress_annotation" . | indent 4 }}
spec:
  tls:
     - secretName: tls-{{ include "ironic_console_endpoint_host_public" . | replace "." "-" }}
       hosts: [{{ include "ironic_console_endpoint_host_public" . }}]
  rules:
    - host: {{ include "ironic_console_endpoint_host_public" . }}
      http:
        paths:
        {{- if $conductor.name }}
        - path: /{{$conductor.name}}
        {{- else }}
        - path: /
        {{- end }}
          pathType: Prefix
          backend:
            service:
            {{- if $conductor.name }}
              name: ironic-conductor-{{$conductor.name}}-console
            {{- else }}
              name: ironic-conductor-console
            {{- end }}
              port: 
                number: 443
    {{- end }}
{{- end }}
