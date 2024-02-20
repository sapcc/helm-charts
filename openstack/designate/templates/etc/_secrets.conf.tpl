[DEFAULT]
transport_url = rabbit://{{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/{{ .Release.Name }}/rabbitmq-user/openstack/username" {{"}}"}}:{{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/{{ .Release.Name }}/rabbitmq-user/openstack/password" {{"}}"}}@{{ include "rabbitmq_host" . }}:{{ .Values.rabbitmq.ports.public | default 5672 }}/

[keystone_authtoken]
username = {{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/{{ .Release.Name }}/keystone-user/service/username" {{"}}"}}
password = {{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/{{ .Release.Name }}/keystone-user/service/password" {{"}}"}}

[storage:sqlalchemy]
# Database connection string - MariaDB for regional setup
# and Percona Cluster for inter-regional setup:
{{ if .Values.percona_cluster.enabled -}}
connection = {{ include "db_url_pxc" . }}
{{- else }}
connection = mysql+pymysql://{{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/{{ .Release.Name }}/mariadb-user/{{ .Release.Name }}/username" {{"}}"}}:{{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/{{ .Release.Name }}/mariadb-user/{{ .Release.Name }}/password" {{"}}"}}@{{ .Release.Name }}-mariadb/{{ (coalesce .Values.dbName .Values.db_name) }}?charset=utf8
{{- end }}

{{ include "ini_sections.audit_middleware_notifications" . }}
