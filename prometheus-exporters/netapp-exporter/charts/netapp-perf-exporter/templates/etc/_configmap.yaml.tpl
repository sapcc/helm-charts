---
kind: ConfigMap
apiVersion: v1
metadata:
  name: {{ .appFullName }}
data:
  {{- if eq .app.component "manila" }}
  netapp-filers.yaml: |
    {{- .netappFilerYaml | nindent 4 }}
  {{- else }}
  netapp-filers.yaml: "TO BE POPULATED BY SIDECAR"
  {{- end }}
  netapp-harvest.conf: |
    {{- .netappHarvestConf | nindent 4 }}
  graphite-mapping.conf: |
    {{- .graphiteConf | nindent 4 }}
