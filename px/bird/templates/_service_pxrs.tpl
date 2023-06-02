{{- define "service_pxrs" -}}
{{- $deployment_name := index . 0 | required "deployment_name cannot be empty" }}
{{- $looking_glass := index . 1 | required "looking_glass cannot be empty" }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $deployment_name }}
  namespace: px
spec:
  ports:
{{- range $lg, $lg_config := $looking_glass }}
  - name: {{ $lg }}proxy
    protocol: TCP
    port: {{ required "proxy_port cannot be empty" $lg_config.proxy_port }}
    targetPort: {{ $lg }}proxy
{{- end }}
  - name: birdwatcher
    protocol: TCP
    port: 29184
    targetPort: birdwatcher
  selector:
    app: {{ $deployment_name }}
{{ end }}
