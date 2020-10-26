---
kind: ConfigMap
apiVersion: v1
metadata:
  name: {{ required "Value apps[].name" .app.fullname }}
data:
  {{- if eq .appName "manila" }}
  netapp-filers.yaml: |
  {{- .manilaFilerYaml | nindent 4 }}
  {{- else }}
  netapp-filers.yaml: "TO BE POPULATED BY SIDECAR"
  {{- end }}
