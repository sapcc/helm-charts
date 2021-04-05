{{- define "image_version" -}}
  {{- if contains "DEFINED" .image_version -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{.image_version}}
  {{- end -}}
{{- end -}}

{{- define "secret_env_vars" -}}
{{- range $key, $val := .Values.passwords }}
{{- if contains "DEFINED" $val }}
  {{ required "This release should be installed by the deployment pipeline!" "" }}
{{- end }}
- name: {{ $key | upper }}
  valueFrom:
    secretKeyRef:
      name: swift-http-import
      key: {{ $key }}
{{- end }}
{{- end -}}
