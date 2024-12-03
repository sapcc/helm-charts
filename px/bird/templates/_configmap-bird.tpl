{{- define "configmap_bird" -}}
{{- $config_path := include "bird.domain.config_path" . }}
---
kind: ConfigMap
apiVersion: v1
metadata:
    name: {{ include "bird.statefulset.configMapName" . }}
    annotations:
        px.cloud.sap/configPath: {{ $config_path | quote }}
        px.cloud.sap/configChecksumSha1: {{ .top.Files.Get $config_path | sha1sum | quote }}
data:
    "bird.conf": |
{{ .top.Files.Get $config_path | indent 6 }}
{{ end }}
