- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest-admin3
  project_id: f71088a0dfd74e15ac547556cb1874ec
  types:
  - admin
  username: neutron-tempestadmin3
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest-admin4
  project_id: fdcf78492695421ab9767832a75d568a
  types:
  - admin
  username: neutron-tempestadmin4
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest5
  username: neutron-tempestuser5
  project_id: f94d4d8356af4e489fbf37d89f9fb16e
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest6
  username: neutron-tempestuser6
  project_id: b9d8f3f6cb3f452ea2fbedf1f3e3d300
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest7
  username: neutron-tempestuser7
  project_id: 82a28321cebd420c80c4fdaf161513a0
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest8
  username: neutron-tempestuser8
  project_id: a2742e77e3a44df2b4522d9c8ce4d9d5
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest9
  username: neutron-tempestuser9
  project_id: 782abfcd3e5345848af52f0f83622804
  types:
  - primary
- domain_name: tempest
  password: {{ .Values.tempestAdminPassword | quote }}
  project_name: neutron-tempest10
  username: neutron-tempestuser10
  project_id: 4063f77d205d415a9abd83a76df66cd3
  types:
  - primary
