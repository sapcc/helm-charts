---
kind: ConfigMap
apiVersion: v1
metadata:
  name: {{ printf "%s-%s" .fullname .appComponent }}
  labels:
    app.kubernetes.io/name: {{ .fullname }}
    app.kubernetes.io/component: {{ .appComponent }}
data:
  {{- if eq .appComponent "manila" }}
  filers.yaml: |
  {{- .manilaFilerYaml | nindent 4 }}
  {{- else }}
  filers.yaml: ""
  {{- end }}
