
export TERM=dumb

mysql -u root --password={{.Values.mariadb.root_password}} <<- EOSQL
	CREATE DATABASE {{.Values.mariadb.name}} CHARACTER SET utf8 COLLATE utf8_general_ci;
        GRANT ALL PRIVILEGES ON {{.Values.mariadb.name}}.* TO {{.Values.global.dbUser}}@localhost IDENTIFIED BY '{{required ".Values.global.dbPassword is missing" .Values.global.dbPassword}}';
        GRANT ALL PRIVILEGES ON {{.Values.mariadb.name}}.* TO {{.Values.global.dbUser}}@'%' IDENTIFIED BY '{{required ".Values.global.dbPassword is missing" .Values.global.dbPassword}}';
EOSQL
