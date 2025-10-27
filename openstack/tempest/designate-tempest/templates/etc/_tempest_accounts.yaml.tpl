- username: 'admin'
  tenant_name: 'admin'
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'admin'
  types:
   - admin
   - primary
- username: 'tempestuser1'
  tenant_name: 'tempest1'
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'tempest1'
  types:
   - reader
   - alt
- username: 'tempestuser2'
  tenant_name: 'tempest2'
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'tempest2'
  types:
   - demo
