[client]
port     = 3306
socket   = /var/run/mysqld/mysqld.sock
password = {{ include "mariadb.root_password" . }}
