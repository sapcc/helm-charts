- username: 'admin'
  tenant_name: 'admin'
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'admin'
  types:
   - admin
   - primary
- username: 'tempestuser3'
  tenant_name: 'tempest3'
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'tempest3'
  types:
   - reader
   - alt
- username: 'tempestuser4'
  tenant_name: 'tempest4'
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'tempest4'
  types:
   - demo
