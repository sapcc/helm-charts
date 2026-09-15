- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest-admin1
  types:
  - admin
  - primary
  username: neutron-tempestadmin1
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest-admin2
  types:
  - admin
  - primary
  username: neutron-tempestadmin2
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest-admin3
  types:
  - admin
  - primary
  username: neutron-tempestadmin3
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest-admin4
  types:
  - admin
  - primary
  username: neutron-tempestadmin4
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest1
  username: neutron-tempestuser1
  roles:
  - network_admin
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest2
  username: neutron-tempestuser2
  roles:
  - network_admin
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest3
  username: neutron-tempestuser3
  roles:
  - network_admin
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest4
  username: neutron-tempestuser4
  roles:
  - network_admin
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest5
  username: neutron-tempestuser5
  roles:
  - network_admin
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest6
  username: neutron-tempestuser6
  roles:
  - network_admin
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest7
  username: neutron-tempestuser7
  roles:
  - network_admin
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
  project_name: neutron-tempest8
  username: neutron-tempestuser8
  roles:
  - network_admin