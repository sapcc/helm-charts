---
# This is the internal user database
# The hash value is a bcrypt hash and can be generated with plugin/tools/hash.sh

_meta:
  type: "internalusers"
  config_version: 2

# Define your internal users here

data:
  hash: "{{ .Values.users.data.nohash }}"
  reserved: true
  backend_roles:
  - "data"

greenhouse:
  hash: "{{ .Values.users.greenhouse.nohash }}"
  reserved: true
  backend_roles:
  - "greenhouse"

storage:
  hash: "{{ .Values.users.storage.nohash }}"
  reserved: true
  backend_roles:
  - "storage"

{{- if .Values.qalogs.enabled }}
dataqade2:
  hash: "{{ .Values.users.dataqade2.nohash }}"
  reserved: true
  backend_roles:
  - "qade2"

dataqade3:
  hash: "{{ .Values.users.dataqade3.nohash }}"
  reserved: true
  backend_roles:
  - "qade3"

dataqade5:
  hash: "{{ .Values.users.dataqade5.nohash }}"
  reserved: true
  backend_roles:
  - "qade5"
{{- end }}

jump:
  hash: "{{ .Values.users.jump.nohash }}"
  reserved: true
  backend_roles:
  - "jump"

jaeger:
  hash: "{{ .Values.users.jaeger.nohash }}"
  reserved: true
  backend_roles:
  - "jaeger"

syslog:
  hash: "{{ .Values.users.syslog.nohash }}"
  reserved: true
  backend_roles:
  - "syslog"

promuser:
  hash: "{{ .Values.users.promuser.nohash }}"
  reserved: true
  backend_roles:
  - "promuser"

admin:
  hash: "{{ .Values.users.admin.nohash }}"
  reserved: true
  backend_roles:
  - "adminrole"

dashboard:
  hash: "{{ .Values.users.dashboard.nohash }}"
  reserved: true
  description: "Demo OpenSearch Dashboards user"

kibanaro:
  hash: "{{ .Values.users.kibanaro.nohash }}"

kibanaserver:
  hash: "{{ .Values.users.kibanaserver.nohash }}"
  reserved: true

maillog:
  hash: "{{ .Values.users.maillog.nohash }}"
  reserved: true
  backend_roles:
  - "maillog"

jupyterhub:
  hash: "{{ .Values.users.jupyterhub.nohash }}"
  reserved: true
  backend_roles:
  - "jupyterhub"
