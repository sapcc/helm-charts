[DEFAULT]

log_config_append = /etc/config/logging.conf
# logging_context_format_string = %(process)d %(levelname)s %(name)s [%(request_id)s g%(global_request_id)s %(user_identity)s] %(instance)s%(message)s
# logging_default_format_string = %(process)d %(levelname)s %(name)s [-] %(instance)s%(message)s
# logging_exception_prefix = %(process)d ERROR %(name)s %(instance)s
# logging_user_identity_format = usr %(user)s prj %(tenant)s dom %(domain)s usr-dom %(user_domain)s prj-dom %(project_domain)s

[bastion]
max_inactive_days={{.Values.bastion.max_inactive_days}}

[database]
enabled = {{.Values.db.enabled}}

loop_interval={{.Values.db.loop_interval}}
max_initial_delay={{.Values.db.max_initial_delay}}
timeout={{.Values.db.timeout}}

# Database connection string - MariaDB for regional setup
# and Percona Cluster for inter-regional setup:
connection = mysql+pymysql://{{ default .Release.Name .Values.db.username }}:{{.Values.db.password }}@{{include "db_host" .}}/{{ default .Release.Name .Values.mariadb.name }}?charset=utf8

[ldap]
enabled = {{.Values.ldap.enabled}}
looping_interval={{.Values.ldap.loop_interval}}
max_initial_delay={{.Values.ldap.max_initial_delay}}
timeout={{.Values.ldap.timeout}}
url = {{.Values.ldap.url}}
query_scope=sub
use_tls = False
user = {{.Values.ldap.username}}
password = {{.Values.ldap.password}}

user_tree_dn = {{.Values.ldap.user_tree_dn}}

