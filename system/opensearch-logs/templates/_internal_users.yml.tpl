---
# This is the internal user database
# The hash value is a bcrypt hash and can be generated with plugin/tools/hash.sh

_meta:
  type: "internalusers"
  config_version: 2

# Define your internal users here

data:
  hash: "{{ .Values.users.data.hash }}"
  reserved: true
  backend_roles:
  - "data"

greenhouse:
  hash: "{{ .Values.users.greenhouse.hash }}"
  reserved: true
  backend_roles:
  - "greenhouse"

storage:
  hash: "{{ .Values.users.storage.hash }}"
  reserved: true
  backend_roles:
  - "storage"

{{- if .Values.qalogs.enabled }}
dataqade2:
  hash: "{{ .Values.users.dataqade2.hash }}"
  reserved: true
  backend_roles:
  - "qade2"

dataqade3:
  hash: "{{ .Values.users.dataqade3.hash }}"
  reserved: true
  backend_roles:
  - "qade3"

dataqade5:
  hash: "{{ .Values.users.dataqade5.hash }}"
  reserved: true
  backend_roles:
  - "qade5"
{{- end }}

jump:
  hash: "{{ .Values.users.jump.hash }}"
  reserved: true
  backend_roles:
  - "jump"

jaeger:
  hash: "{{ .Values.users.jaeger.hash }}"
  reserved: true
  backend_roles:
  - "jaeger"

syslog:
  hash: "{{ .Values.users.syslog.hash }}"
  reserved: true
  backend_roles:
  - "syslog"

promuser:
  hash: "{{ .Values.users.promuser.hash }}"
  reserved: true
  backend_roles:
  - "promuser"

admin:
  hash: "{{ .Values.users.admin.hash }}"
  reserved: true
  backend_roles:
  - "adminrole"

dashboard:
  hash: "{{ .Values.users.dashboard.hash }}"
  reserved: true
  description: "Demo OpenSearch Dashboards user"

kibanaro:
  hash: "{{ .Values.users.kibanaro.hash }}"

kibanaserver:
  hash: "{{ .Values.users.kibanaserver.hash }}"
  reserved: true

maillog:
  hash: "{{ .Values.users.maillog.hash }}"
  reserved: true
  backend_roles:
  - "maillog"

jupyterhub:
  hash: "{{ .Values.users.jupyterhub.hash }}"
  reserved: true
  backend_roles:
  - "jupyterhub"
