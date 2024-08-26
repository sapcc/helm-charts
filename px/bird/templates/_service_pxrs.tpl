{{- define "service_pxrs" -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "bird.statefulset.deployment_name" . }}
spec:
  ports:
{{- range $lg, $lg_config := .top.Values.looking_glass }}
  - name: {{ $lg }}proxy
    protocol: TCP
    port: {{ required "proxy_port cannot be empty" $lg_config.proxy_port }}
    targetPort: {{ $lg }}proxy
{{- end }}
  selector:
    app: {{ include "bird.statefulset.deployment_name" . }}
{{ end }}
