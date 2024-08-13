---
# This is the internal user database
# The hash value is a bcrypt hash and can be generated with plugin/tools/hash.sh

_meta:
  type: "internalusers"
  config_version: 2

# Define your internal users here

data:
  hash: "{{ .Values.users.data.password }}"
  reserved: true
  backend_roles:
  - "data"

greenhouse:
  hash: "{{ .Values.users.greenhouse.password }}"
  reserved: true
  backend_roles:
  - "greenhouse"

storage:
  hash: "{{ .Values.users.storage.password }}"
  reserved: true
  backend_roles:
  - "storage"

compute:
  hash: "{{ .Values.users.compute.password }}"
  reserved: true
  backend_roles:
  - "compute"

otel:
  hash: "{{ .Values.users.otel.password }}"
  reserved: true
  backend_roles:
  - "otel"

otellogs:
  hash: "{{ .Values.users.otellogs.password }}"
  reserved: true
  backend_roles:
  - "otellogs"

{{- if .Values.qalogs.enabled }}
dataqade2:
  hash: "{{ .Values.users.dataqade2.password }}"
  reserved: true
  backend_roles:
  - "qade2"

dataqade3:
  hash: "{{ .Values.users.dataqade3.password }}"
  reserved: true
  backend_roles:
  - "qade3"

dataqade5:
  hash: "{{ .Values.users.dataqade5.password }}"
  reserved: true
  backend_roles:
  - "qade5"

oraboskvm:
  hash: "{{ .Values.users.oraboskvm.password }}"
  reserved: true
  backend_roles:
  - "oraboskvm"

otelstorage:
  hash: "{{ .Values.users.otelstorage.password }}"
  reserved: true
  backend_roles:
  - "otelstorage"
{{- end }}

jump:
  hash: "{{ .Values.users.jump.password }}"
  reserved: true
  backend_roles:
  - "jump"

jaeger:
  hash: "{{ .Values.users.jaeger.password }}"
  reserved: true
  backend_roles:
  - "jaeger"

syslog:
  hash: "{{ .Values.users.syslog.password }}"
  reserved: true
  backend_roles:
  - "syslog"

promuser:
  hash: "{{ .Values.users.promuser.password }}"
  reserved: true
  backend_roles:
  - "promuser"

admin:
  hash: "{{ .Values.users.admin.password }}"
  reserved: true
  backend_roles:
  - "adminrole"

dashboard:
  hash: "{{ .Values.users.dashboard.password }}"
  reserved: true
  description: "Demo OpenSearch Dashboards user"

kibanaro:
  hash: "{{ .Values.users.kibanaro.password }}"

kibanaserver:
  hash: "{{ .Values.users.kibanaserver.password }}"
  reserved: true

maillog:
  hash: "{{ .Values.users.maillog.password }}"
  reserved: true
  backend_roles:
  - "maillog"

jupyterhub:
  hash: "{{ .Values.users.jupyterhub.password }}"
  reserved: true
  backend_roles:
  - "jupyterhub"
