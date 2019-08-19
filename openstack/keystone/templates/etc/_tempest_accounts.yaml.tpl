- username: 'tempestuser1'
  tenant_name: 'tempest1'
  password: {{ .Values.tempest.userPassword | quote }}
  project_name: 'tempest1'
- username: 'tempestuser2'
  tenant_name: 'tempest2'
  password: {{ .Values.tempest.userPassword | quote }}
  project_name: 'tempest2'
- username: 'tempestuser3'
  tenant_name: 'tempest3'
  password: {{ .Values.tempest.userPassword | quote }}
  project_name: 'tempest3'
- username: 'tempestuser4'
  tenant_name: 'tempest4'
  password: {{ .Values.tempest.userPassword | quote }}
  project_name: 'tempest4'
- username: 'tempestuser5'
  tenant_name: 'tempest5'
  password: {{ .Values.tempest.userPassword | quote }}
  project_name: 'tempest5'
- username: 'admin'
  password: {{ required "A valid .Values.tempest.adminPassword required!" .Values.tempest.adminPassword | quote }}
  tenant_name: 'admin'
  project_name: 'admin'
  types:
  - admin
