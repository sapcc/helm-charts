#!/bin/sh

# cat /var/lib/initdb/init.sql
MYSQL_PWD=$MYSQL_PASSWORD mysql -h $MYSQL_ADDRESS -u $MYSQL_USERNAME --batch -e "source /var/lib/initdb/init.sql"

echo -n 'True' && exit 0
