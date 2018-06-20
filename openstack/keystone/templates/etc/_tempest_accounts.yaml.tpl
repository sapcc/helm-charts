- username: 'tempestuser1'
  tenant_name: 'tempest1'
  password: {{ .Values.tempest.userPassword | quote }}
  project_name: 'tempest1'
- username: 'tempestuser2'
  tenant_name: 'tempest2'
  password: {{ .Values.tempest.userPassword | quote }}
  project_name: 'tempest2'
