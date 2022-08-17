USE mysql;
set @rolename := '${DB_ROLE}';
SET @code := CONCAT("${SQL_CODE} ", @rolename, " ${WITH_OPTION}");
PREPARE stmt_runcode FROM @code;
EXECUTE stmt_runcode;
DROP PREPARE stmt_runcode;
FLUSH USER_VARIABLES;
SET @grantperms := CONCAT("GRANT ALL ON *.* TO ", QUOTE(@user), "@", QUOTE(@host), " WITH GRANT OPTION");