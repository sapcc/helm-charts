- username: 'admin'
  tenant_name: 'admin'
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'admin'
  types:
   - admin
- username: 'tempestuser3'
  tenant_name: 'tempest3'
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'tempest3'
- username: 'tempestuser4'
  tenant_name: 'tempest4'
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'tempest4'
