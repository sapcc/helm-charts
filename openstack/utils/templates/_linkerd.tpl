{{- define "utils.linkerd.pod_and_service_annotation" }}
{{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested }}
linkerd.io/inject: enabled
{{- end }}
{{- end }}

{{- define "utils.linkerd.ingress_annotation" }}
{{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested }}
ingress.kubernetes.io/service-upstream: "true"
nginx.ingress.kubernetes.io/service-upstream: "true"
{{- end }}
{{- end }}
