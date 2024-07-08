{{- define "configmap_bird" -}}
{{- $files := index . 0 -}}
{{- $bird_config_path := index . 1 | required "bird_config_path cannot be empty" }}
{{- $config_name := index . 2 | required "config_name cannot be empty" }}

{{- $config_path := printf "%s%s.conf" $bird_config_path $config_name -}}
---
kind: ConfigMap
apiVersion: v1
metadata:
    name: cfg-{{ $config_name }}
data:
    "bird.conf": |
{{- if not ($files.Glob $config_path) -}}
{{- fail (printf "bird config file %s does not exist."  $config_path ) -}}
{{- end }}
{{ $files.Get $config_path | indent 6 }}

{{ end }}
