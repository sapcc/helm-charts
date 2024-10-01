#!/bin/sh

# Check that we can connect and use operator credentials to access database
while ! mysql -h "${MYSQL_ADDRESS}" -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" > /dev/null 2>&1
do
  echo "Connection to ${MYSQL_ADDRESS} MySQL using ${MYSQL_USERNAME} credentials failed. Retrying in 5 seconds..."
  sleep 5
done

echo "Connection successful"

echo "Running init.sql"
MYSQL_PWD=$MYSQL_PASSWORD mysql -h "${MYSQL_ADDRESS}" -u "${MYSQL_USERNAME}" --batch -e "source /var/lib/initdb/init.sql"
echo "Finished"

exit 0
