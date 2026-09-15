- username: 'tempestuser1'
  password: '{{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}'
  tenant_name: 'tempest1'
  project_name: 'tempest1'
  roles:
  - key-manager:service-admin
- username: 'tempestuser2'
  password: '{{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}'
  tenant_name: 'tempest2'
  project_name: 'tempest2'
  roles:
  - key-manager:service-admin
- username: 'admin'
  password: '{{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}'
  tenant_name: 'admin'
  project_name: 'admin'
  types:
  - admin
