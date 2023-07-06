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

kibanaserver:
  hash: "{{ .Values.users.kibanaserver.hash }}"
  reserved: true
  description: "Demo OpenSearch Dashboards user"

kibanaro:
  hash: "{{ .Values.users.kibanaro.hash }}"
  reserved: false
  backend_roles:
  - "kibanauser"
  - "readall"
  attributes:
    attribute1: "value1"
    attribute2: "value2"
    attribute3: "value3"
  description: "Demo OpenSearch Dashboards read only user"

maillog:
  hash: "{{ .Values.users.maillog.hash }}"
  reserved: true
  backend_roles:
  - "maillog"
