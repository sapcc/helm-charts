{{/*
Render the EncryptionConfiguration YAML for a single encryption key.
Expects a dict with keys: keyName, keySecret, resources (list of strings).
Provider is always aescbc (hardcoded; not in public repo values).
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
