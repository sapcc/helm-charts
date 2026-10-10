{{/*
Render the EncryptionConfiguration YAML.
Expects a dict with keys: keyName, keySecret, resources (list of strings),
and provider (string).
*/}}
{{- define "cc-runtime-cluster.encryptionConfig" -}}
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
{{- range .resources }}
      - {{ . }}
{{- end }}
    providers:
      - {{ .provider }}:
          keys:
            - name: {{ .keyName }}
              secret: {{ .keySecret }}
      - identity: {}
{{- end -}}
