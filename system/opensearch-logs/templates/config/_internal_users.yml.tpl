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

data2:
  hash: "{{ .Values.users.data2.nohash }}"
  reserved: true
  backend_roles:
  - "data"

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

syslog:
  hash: "{{ .Values.users.syslog.nohash }}"
  reserved: true
  backend_roles:
  - "syslog"

syslog2:
  hash: "{{ .Values.users.syslog2.nohash }}"
  reserved: true
  backend_roles:
  - "syslog"

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

{{- if .Values.qalogs.enabled }}
dataqade2:
  hash: "{{ .Values.users.dataqade2.nohash }}"
  reserved: true
  backend_roles:
  - "data"

dataqade3:
  hash: "{{ .Values.users.dataqade3.nohash }}"
  reserved: true
  backend_roles:
  - "data"

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
  hash: "{{ .Values.users.jupyterhub.nohash }}"
  reserved: true
  backend_roles:
  - "promuser"

ronly2:
  hash: "{{ .Values.users.jupyterhub2.nohash }}"
  reserved: true
  backend_roles:
  - "promuser"

oraboskvm:
  hash: "{{ .Values.users.oraboskvm.nohash }}"
  reserved: true
  backend_roles:
  - "oraboskvm"

oraboskvm2:
  hash: "{{ .Values.users.oraboskvm2.nohash }}"
  reserved: true
  backend_roles:
  - "oraboskvm"
{{- end }}

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

dashboard:
  hash: "{{ .Values.users.dashboard.nohash }}"
  reserved: true
  description: "Demo OpenSearch Dashboards user"

dashboard2:
  hash: "{{ .Values.users.dashboard2.nohash }}"
  reserved: true
  description: "Demo OpenSearch Dashboards user"

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
  - "maillog"

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

alerting:
  hash: "{{ .Values.users.alerting.nohash }}"
  reserved: true
  backend_roles:
  - "auditorrole"

alerting2:
  hash: "{{ .Values.users.alerting2.nohash }}"
  reserved: true
  backend_roles:
  - "auditorrole"
