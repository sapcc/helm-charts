{{/*
Render the EncryptionConfiguration YAML for a single aescbc key.
Expects a dict with keys: keyName, keySecret, resources (list of strings).
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
      - aescbc:
          keys:
            - name: {{ .keyName }}
              secret: {{ .keySecret }}
      - identity: {}
{{- end -}}
