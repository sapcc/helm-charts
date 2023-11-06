---
# This is the internal user database
# The hash value is a bcrypt hash and can be generated with plugin/tools/hash.sh

_meta:
  type: "internalusers"
  config_version: 2

# Define your internal users here

audit:
  hash: "{{ .Values.global.users.audit.hash }}"
  reserved: true
  backend_roles:
  - "audit"

promuser:
  hash: "{{ .Values.global.users.promuser.hash }}"
  reserved: true
  backend_roles:
  - "promuser"

admin:
  hash: "{{ .Values.global.users.admin.hash }}"
  reserved: true
  backend_roles:
  - "adminrole"

kibanaserver:
  hash: "{{ .Values.global.users.kibanaserver.hash }}"
  reserved: true
  description: "Demo OpenSearch Dashboards user"
