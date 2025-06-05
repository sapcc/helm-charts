{{- define "surveyor_environment" }}
# TODO: SURVEYOR_AUDIT_*
- name:  SURVEYOR_DB_USERNAME
  value: 'surveyor'
- name:  SURVEYOR_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $.Release.Name }}-pguser-surveyor'
      key: 'postgres-password'
- name:  SURVEYOR_DEBUG
  value: 'false'
{{- end }}
