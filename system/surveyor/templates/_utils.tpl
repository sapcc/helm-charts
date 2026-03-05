{{- define "surveyor_image" -}}
  {{- $registry := $.Values.global.registry    | required "missing value for .Values.global.registry" -}}
  {{- $tag      := $.Values.surveyor.image_tag | required "This release should be installed by the deployment pipeline!" -}}
  {{- printf "%s/surveyor:%s" $registry $tag -}}
{{- end -}}

{{- define "surveyor_environment" }}
# TODO: SURVEYOR_AUDIT_*
- name: SURVEYOR_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
- name: SURVEYOR_DB_HOSTNAME
  value: "surveyor-postgresql.{{ .Release.Namespace }}.svc"
- name:  SURVEYOR_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $.Release.Name }}-pguser-surveyor'
      key: 'postgres-password'
- name:  SURVEYOR_DB_USERNAME
  value: 'surveyor'
- name:  SURVEYOR_DEBUG
  value: 'false'
{{- end }}
