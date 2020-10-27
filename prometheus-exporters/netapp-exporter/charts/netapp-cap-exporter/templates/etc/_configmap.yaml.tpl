---
kind: ConfigMap
apiVersion: v1
metadata:
  name: {{ .fullname }}
  labels:
    app.kubernetes.io/name: {{ .fullname }}
    app.kubernetes.io/component: {{ .appComponent }}
data:
  {{- if eq .appComponent "manila" }}
  netapp-filers.yaml: |
  {{- .manilaFilerYaml | nindent 4 }}
  {{- else }}
  netapp-filers.yaml: "TO BE POPULATED BY SIDECAR"
  {{- end }}
