
export TERM=dumb

mysql -u root --password={{ include "mariadb.root_password" . }} <<- EOSQL
	CREATE DATABASE {{.Values.name}} CHARACTER SET utf8 COLLATE utf8_general_ci;
        GRANT ALL PRIVILEGES ON {{.Values.name}}.* TO {{.Values.global.dbUser}}@localhost IDENTIFIED BY '{{include "db_password" .}}';
        GRANT ALL PRIVILEGES ON {{.Values.name}}.* TO {{.Values.global.dbUser}}@'%' IDENTIFIED BY '{{include "db_password" .}}';
EOSQL
