{{ define "utils.snippets.set_ingress_cors_annotations" }}
{{- if .Values.cors.enabled }}
ingress.kubernetes.io/enable-cors: "true"
nginx.ingress.kubernetes.io/enable-cors: "true"
ingress.kubernetes.io/cors-allow-headers: "{{ .Values.utils.cors.allow_headers }}{{ if .Values.cors.additional_allow_headers }},{{ .Values.cors.additional_allow_headers }}{{ end }}"
nginx.ingress.kubernetes.io/cors-allow-headers: "{{ .Values.utils.cors.allow_headers }}{{ if .Values.cors.additional_allow_headers }},{{ .Values.cors.additional_allow_headers }}{{ end }}"
ingress.kubernetes.io/cors-expose-headers: "{{ .Values.cors.expose_headers | default "*" }}"
nginx.ingress.kubernetes.io/cors-expose-headers: "{{ .Values.cors.expose_headers | default "*" }}"
ingress.kubernetes.io/cors-allow-origin: "{{ required ".Values.global.accessControlAllowOrigin is missing" .Values.global.accessControlAllowOrigin }}{{if .Values.cors.additional_allow_origin }},{{ .Values.cors.additional_allow_origin }}{{ end }}"
nginx.ingress.kubernetes.io/cors-allow-origin: "{{ required ".Values.global.accessControlAllowOrigin is missing" .Values.global.accessControlAllowOrigin }}{{if .Values.cors.additional_allow_origin }},{{ .Values.cors.additional_allow_origin }}{{ end }}"
ingress.kubernetes.io/cors-allow-credentials: "{{ .Values.cors.allow_credentials | default "false" }}"
nginx.ingress.kubernetes.io/cors-allow-credentials: "{{ .Values.cors.allow_credentials | default "false" }}"
ingress.kubernetes.io/cors-max-age: "{{ .Values.cors.max_age | default "1728000" }}"
nginx.ingress.kubernetes.io/cors-max-age: "{{ .Values.cors.max_age | default "1728000" }}"
{{- end }}
{{- end }}
