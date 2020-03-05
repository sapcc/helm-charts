# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:

host    all             all             127.0.0.1/32            trust

# IPv6 local connections:
host    all             all             ::1/128                 trust

# Allow replication connections from localhost, by a user with the
# replication privilege.
#local   replication     postgres                                trust
#host    replication     postgres        127.0.0.1/32            trust
#host    replication     postgres        ::1/128                 trust

{{- if $.Values.cdc.enabled }}
# All replication connections from Debezium connector running on KafkaConnect
local   replication     debezium                                trust
host    replication     debezium        127.0.0.1/32            trust
host    replication     debezium        ::1/128                 trust
# permit access from same cluster network (Kubernikus)
host    replication     debezium        100.68.0.0/16          trust
{{- end }}

host all all {{ .Values.hba_cidr }} {{if not (or .Values.pgbouncer.enabled .Values.global.pgbouncer.enabled ) }}{{ .Values.auth_method }}{{ else }}md5{{ end }}
