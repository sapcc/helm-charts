{{- define "configmap_bird" -}}
{{ $config_name := include "bird.domain.config_name" . }}
{{ $config_path := include "bird.domain.config_path" . }}
---
kind: ConfigMap
apiVersion: v1
metadata:
    name: {{ $config_name }}
    annotations:
        px.cloud.sap/configPath: {{ $config_path | quote }}
        px.cloud.sap/configChecksumSha1: {{ .top.Files.Get $config_path | sha1sum | quote }}
data:
    "bird.conf": |
{{- if not (.top.Files.Glob $config_path) -}}
{{- fail (printf "bird config file %s does not exist."  $config_path ) -}}
{{- end }}
{{ .top.Files.Get $config_path | indent 6 }}

{{ end }}
