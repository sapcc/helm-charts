USE mysql;
SET @host := '${DB_HOST}';
SET @user := '${DB_USERNAME}';
SET @dropuser := CONCAT("DROP USER IF EXISTS ", QUOTE(@user), "@", QUOTE(@host));
PREPARE stmt_runcode FROM @dropuser;
EXECUTE stmt_runcode;
DROP PREPARE stmt_runcode;
FLUSH USER_VARIABLES;
