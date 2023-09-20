# By default the Ingress-Nginx Controller uses a list of all endpoints (Pod IP/port) in the NGINX upstream configuration.
# We need to disable this behavior and force it to go through the service IP because the pod-level endpoints require mTLS.
{{- define "linkerd_annotations_for_ingress" -}}
{{- if .Values.global.linkerdEnabled -}}
nginx.ingress.kubernetes.io/service-upstream: "true"
{{- end -}}
{{- end -}}
