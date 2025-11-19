#!/bin/bash
set -eo pipefail
shopt -s nullglob

escape_special() {
	{ set +x; } 2>/dev/null
	echo "$1" |
		sed 's/\\/\\\\/g' |
		sed 's/'\''/'\\\\\''/g' |
		sed 's/"/\\\"/g'
}

mysql_pass=$(cat /etc/mysql/mysql-users-secret/root || :)
MYSQL_PASSWORD="${mysql_pass:-$MYSQL_ROOT_PASSWORD}"

cat > /etc/mysql/init-file/init.sql <<-EOSQL || true
SET SESSION sql_log_bin=0;
CREATE USER IF NOT EXISTS 'root'@'localhost';
CREATE USER IF NOT EXISTS 'root'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket;
ALTER USER 'root'@'%' IDENTIFIED BY '$(escape_special "${MYSQL_PASSWORD}")';
GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOSQL
