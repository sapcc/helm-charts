- username: 'tempestuser1'
  password: {{ .Values.tempestAdminPassword | quote }}
  tenant_name: 'tempest1'
  project_name: 'tempest1'
- username: 'tempestuser2'
  password: {{ .Values.tempestAdminPassword | quote }}
  tenant_name: 'tempest2'
  project_name: 'tempest2'
- username: 'admin'
  password: {{ .Values.tempestAdminPassword | quote }}
  tenant_name: 'admin'
  project_name: 'admin'
  types:
  - admin
