---
# This is the internal user database
# The hash value is a bcrypt hash and can be generated with plugin/tools/hash.sh

_meta:
  type: "internalusers"
  config_version: 2

# Define your internal users here

audit:
  hash: "{{ .Values.global.users.audit.password_resolve }}"
  reserved: true
  backend_roles:
  - "audit"

audit2:
  hash: "{{ .Values.global.users.audit2.password_resolve }}"
  reserved: true
  backend_roles:
  - "audit"

promuser:
  hash: "{{ .Values.global.users.promuser.password_resolve }}"
  reserved: true
  backend_roles:
  - "promuser"

promuser2:
  hash: "{{ .Values.global.users.promuser2.password_resolve }}"
  reserved: true
  backend_roles:
  - "promuser"

admin:
  hash: "{{ .Values.global.users.admin.password_resolve }}"
  reserved: true
  backend_roles:
  - "adminrole"

admin2:
  hash: "{{ .Values.global.users.admin2.password_resolve }}"
  reserved: true
  backend_roles:
  - "adminrole"

kibanaserver:
  hash: "{{ .Values.global.users.kibanaserver.password_resolve }}"
  reserved: true
  description: "OpenSearch Dashboards user"

kibanaserver2:
  hash: "{{ .Values.global.users.kibanaserver2.password_resolve }}"
  reserved: true
  description: "OpenSearch Dashboards user"
