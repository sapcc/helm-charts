#!/bin/bash

echo "Safely shutting down MySQL/MariaDB"
filename="var/lib/mysql/mon_full_dump_$(date --utc +'%Y-%m-%d_%H%M').sql"
echo "* creating SQL dump of 'mon' DB in $filename"
# use single-transaction to avoid inconsistencies
mysqldump mon --lock-tables --verbose > $filename 
echo "* invoking stop command on MySQL/MariaDB"
/etc/init.d/mysql stop
