---
kind: ConfigMap
apiVersion: v1
metadata:
  name: {{ printf "%s-%s" .fullname .component }}
  labels:
    app.kubernetes.io/name: {{ .fullname }}
    app.kubernetes.io/component: {{ .component }}
data:
  {{- if eq .component "manila" }}
  netapp-filers.yaml: |
    {{- .netappFilerYaml | nindent 4 }}
  {{- else }}
  netapp-filers.yaml: "TO BE POPULATED BY SIDECAR"
  {{- end }}
  netapp-harvest.conf: |
    {{- .netappHarvestConf | nindent 4 }}
  graphite-mapping.conf: |
    {{- .graphiteConf | nindent 4 }}
