- username: 'tempestuser1'
  tenant_name: 'tempest1'
  password: {{ .Values.tempest.userPassword | quote }}
  project_name: 'tempest1'
- username: 'tempestuser2'
  tenant_name: 'tempest2'
  password: {{ .Values.tempest.userPassword | quote }}
  project_name: 'tempest2'
- username: 'admin'
  password: {{ .Values.tempest.adminPassword | quote }}
  tenant_name: 'admin'
  project_name: 'admin'
  types:
  - admin
