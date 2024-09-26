#!/bin/sh

echo "Running init.sql"
MYSQL_PWD=$MYSQL_PASSWORD mysql -h $MYSQL_ADDRESS -u $MYSQL_USERNAME --batch -e "source /var/lib/initdb/init.sql"
echo "Finished"

exit 0
