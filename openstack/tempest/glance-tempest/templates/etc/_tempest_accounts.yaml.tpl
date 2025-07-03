- username: 'tempestuser3'
  password: {{ .Values.tempestAdminPassword | quote }}
  tenant_name: 'tempest3'
  project_name: 'tempest3'
- username: 'tempestuser4'
  password: {{ .Values.tempestAdminPassword | quote }}
  tenant_name: 'tempest4'
  project_name: 'tempest4'
- username: 'admin'
  password: {{ .Values.tempestAdminPassword | quote }}
  tenant_name: 'admin'
  project_name: 'admin'
  types:
  - admin
