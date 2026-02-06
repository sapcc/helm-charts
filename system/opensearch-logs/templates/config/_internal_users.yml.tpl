---
# This is the internal user database
# The hash value is a bcrypt hash and can be generated with plugin/tools/hash.sh

_meta:
  type: "internalusers"
  config_version: 2

# Define your internal users here

admin:
  hash: "{{ .Values.users.admin.nohash }}"
  reserved: true
  backend_roles:
  - "adminrole"

admin2:
  hash: "{{ .Values.users.admin2.nohash }}"
  reserved: true
  backend_roles:
  - "adminrole"

audit:
  hash: "{{ .Values.users.audit.nohash }}"
  reserved: true
  backend_roles:
  - "audit"

audit2:
  hash: "{{ .Values.users.audit2.nohash }}"
  reserved: true
  backend_roles:
  - "audit"

awx:
  hash: "{{ .Values.users.awx.nohash }}"
  reserved: true
  backend_roles:
  - "awx"

awx2:
  hash: "{{ .Values.users.awx2.nohash }}"
  reserved: true
  backend_roles:
  - "awx"
compute:
  hash: "{{ .Values.users.compute.nohash }}"
  reserved: true
  backend_roles:
  - "compute"

compute2:
  hash: "{{ .Values.users.compute2.nohash }}"
  reserved: true
  backend_roles:
  - "compute"

data:
  hash: "{{ .Values.users.data.nohash }}"
  reserved: true
  backend_roles:
  - "data"

data2:
  hash: "{{ .Values.users.data2.nohash }}"
  reserved: true
  backend_roles:
  - "data"

jaeger:
  hash: "{{ .Values.users.jaeger.nohash }}"
  reserved: true
  backend_roles:
  - "jaeger"

jaeger2:
  hash: "{{ .Values.users.jaeger2.nohash }}"
  reserved: true
  backend_roles:
  - "jaeger"

jump:
  hash: "{{ .Values.users.jump.nohash }}"
  reserved: true
  backend_roles:
  - "jump"

jump2:
  hash: "{{ .Values.users.jump2.nohash }}"
  reserved: true
  backend_roles:
  - "jump"

jupyterhub:
  hash: "{{ .Values.users.jupyterhub.nohash }}"
  reserved: true
  backend_roles:
  - "jupyterhub"

jupyterhub2:
  hash: "{{ .Values.users.jupyterhub2.nohash }}"
  reserved: true
  backend_roles:
  - "jupyterhub"

kibanaserver:
  hash: "{{ .Values.users.kibanaserver.nohash }}"
  reserved: true

kibanaserver2:
  hash: "{{ .Values.users.kibanaserver2.nohash }}"
  reserved: true

maillog:
  hash: "{{ .Values.users.maillog.nohash }}"
  reserved: true
  backend_roles:
  - "maillog"

maillog2:
  hash: "{{ .Values.users.maillog2.nohash }}"
  reserved: true
  backend_roles:
  - "maillog2"

promuser:
  hash: "{{ .Values.users.promuser.nohash }}"
  reserved: true
  backend_roles:
  - "promuser"

promuser2:
  hash: "{{ .Values.users.promuser2.nohash }}"
  reserved: true
  backend_roles:
  - "promuser"

storage:
  hash: "{{ .Values.users.storage.nohash }}"
  reserved: true
  backend_roles:
  - "storage"

storage2:
  hash: "{{ .Values.users.storage2.nohash }}"
  reserved: true
  backend_roles:
  - "storage"

{{- if .Values.qalogs.enabled }}
otel:
  hash: "{{ .Values.users.otel.nohash }}"
  reserved: true
  backend_roles:
  - "otel"

otel2:
  hash: "{{ .Values.users.otel2.nohash }}"
  reserved: true
  backend_roles:
  - "otel"

ronly:
  hash: "{{ .Values.users.ronly.nohash }}"
  reserved: true
  backend_roles:
  - "promuser"

ronly2:
  hash: "{{ .Values.users.ronly.nohash }}"
  reserved: true
  backend_roles:
  - "promuser"
{{- end }}
