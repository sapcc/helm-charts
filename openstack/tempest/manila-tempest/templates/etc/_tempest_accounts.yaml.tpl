- username: 'manila-tempestuser1'
  domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'tempest1'
  resources:
    network: share-service
- username: 'manila-tempestuser2'
  domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'tempest2'
  resources:
    network: share-service
- username: 'admin'
  domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: 'admin'
  resources:
    network: share-service
  types:
  - admin
