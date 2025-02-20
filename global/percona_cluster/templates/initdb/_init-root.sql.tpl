SET sql_mode = CONCAT(@@sql_mode, ',NO_BACKSLASH_ESCAPES');
SET SESSION wsrep_on=OFF;
SET SESSION sql_log_bin=0;
ALTER USER 'root'@'localhost' IDENTIFIED BY {{ include "percona-cluster.resolve_secret_squote" .Values.root_password }};
ALTER USER 'root'@'%' IDENTIFIED BY {{ include "percona-cluster.resolve_secret_squote" .Values.root_password }};
FLUSH PRIVILEGES;
