#!/bin/sh

echo "Running init.sql"

MYSQL_RESPONSE=$(MYSQL_PWD="${MYSQL_PASSWORD}" mysql -h "${MYSQL_ADDRESS}" -u "${MYSQL_USERNAME}" --batch -e "source /var/lib/initdb/init.sql")
MYSQL_STATUS=$?
MYSQL_QUERY_STATUS=$(echo "${MYSQL_RESPONSE}" | grep "Error" | wc -l)

if [ "${MYSQL_STATUS}" -ne 0 ] || [ "${MYSQL_QUERY_STATUS}" -ne 0 ]; then
  echo "Running init.sql failed"
  echo "${MYSQL_RESPONSE}"
  exit 1
else
  echo "Running init.sql done"
  exit 0
fi
