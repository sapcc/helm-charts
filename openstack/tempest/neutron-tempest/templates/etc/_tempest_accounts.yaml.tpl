- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest-admin1
  project_id: 3af1c3304e3c494aa798767243b9e434
  types:
  - admin
  username: neutron-tempestadmin1
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest-admin2
  project_id: 486ece4535a44096be6ae216139249f2
  types:
  - admin
  username: neutron-tempestadmin2
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest1
  username: neutron-tempestuser1
  project_id: 7243f3f80a99434292d6766069d3961a
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest2
  username: neutron-tempestuser2
  project_id: 32e0d9ed2f97404d95fc0c77dbeabc63
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest3
  username: neutron-tempestuser3
  project_id: b5f8d5ce914946baa92f62f3103f01a2
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest4
  username: neutron-tempestuser4
  project_id: d6fa3d14f30f4b169be1af0ae4b5dd9c
  types:
  - primary
