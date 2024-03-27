CREATE DATABASE {{.Values.db_name}};
CREATE ROLE {{.Values.global.dbUser}} WITH ENCRYPTED PASSWORD '{{required ".Values.global.dbPassword is missing" .Values.global.dbPassword}}' LOGIN;
GRANT ALL PRIVILEGES ON DATABASE {{.Values.db_name}} TO {{.Values.global.dbUser}};
