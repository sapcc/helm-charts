[client]
port     = 3306
socket   = /var/run/mysqld/mysqld.sock
password = {{ include "mariadb.resolve_secret_for_ini" (required ".Values.root_password missing" .Values.root_password) }}
