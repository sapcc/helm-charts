USE mysql;
SET @host := '${DB_HOST}';
SET @user := '${DB_USERNAME}';
SET @rolename := '${DB_ROLE}';
SET @setdefaultrole := CONCAT("SET DEFAULT ROLE ", @rolename, " FOR ", QUOTE(@user), "@", QUOTE(@host));
PREPARE stmt_runcode FROM @setdefaultrole;
EXECUTE stmt_runcode;
DROP PREPARE stmt_runcode;
FLUSH USER_VARIABLES;