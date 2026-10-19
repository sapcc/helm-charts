- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest-admin1
  types:
  - admin
  username: neutron-tempestadmin1
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest1
  username: neutron-tempestuser1
