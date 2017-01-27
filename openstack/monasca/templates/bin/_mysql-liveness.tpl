#!/bin/bash

# check if the user created latest in the schema exists in the db
/usr/bin/mysql -u root -e "SHOW GLOBAL STATUS LIKE 'Innodb_deadlocks'" | grep -w -q "0"
