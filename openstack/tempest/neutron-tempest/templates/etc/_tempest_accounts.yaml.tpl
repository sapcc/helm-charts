- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest-admin1
  project_id: 3af1c3304e3c494aa798767243b9e434
  types:
  - admin
  username: neutron-tempestadmin1
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest-admin2
  project_id: 486ece4535a44096be6ae216139249f2
  types:
  - admin
  username: neutron-tempestadmin2
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest-admin3
  project_id: f71088a0dfd74e15ac547556cb1874ec
  types:
  - admin
  username: neutron-tempestadmin3
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest-admin4
  project_id: fdcf78492695421ab9767832a75d568a
  types:
  - admin
  username: neutron-tempestadmin4
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest1
  username: neutron-tempestuser1
  project_id: 7243f3f80a99434292d6766069d3961a
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest2
  username: neutron-tempestuser2
  project_id: 32e0d9ed2f97404d95fc0c77dbeabc63
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest3
  username: neutron-tempestuser3
  project_id: b5f8d5ce914946baa92f62f3103f01a2
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest4
  username: neutron-tempestuser4
  project_id: d6fa3d14f30f4b169be1af0ae4b5dd9c
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest5
  username: neutron-tempestuser5
  project_id: f94d4d8356af4e489fbf37d89f9fb16e
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest6
  username: neutron-tempestuser6
  project_id: b9d8f3f6cb3f452ea2fbedf1f3e3d300
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest7
  username: neutron-tempestuser7
  project_id: 82a28321cebd420c80c4fdaf161513a0
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest8
  username: neutron-tempestuser8
  project_id: a2742e77e3a44df2b4522d9c8ce4d9d5
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest9
  username: neutron-tempestuser9
  project_id: 782abfcd3e5345848af52f0f83622804
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
  project_name: neutron-tempest10
  username: neutron-tempestuser10
  project_id: 4063f77d205d415a9abd83a76df66cd3
  types:
  - primary
