#!/usr/bin/env bash
set +e
set -u
set -o pipefail

if [[ -z "${MYSQL_ADDRESS}" ]] || [[ -z "${MYSQL_USERNAME}" ]] || [[ -z "${MYSQL_PASSWORD}" ]]; then
  echo "Error: Missing required environment variables. MYSQL_ADDRESS, MYSQL_USERNAME and MYSQL_PASSWORD must be set."
  exit 1
fi

function checkdblogon() {
  if MYSQL_PWD="${MYSQL_PASSWORD}" mysql -h "${MYSQL_ADDRESS}" -u "${MYSQL_USERNAME}" --database=mysql --wait --connect-timeout=10 --reconnect --execute="STATUS;" | grep 'Server version'; then
    if MYSQL_PWD="${MYSQL_PASSWORD}" mysql -h "${MYSQL_ADDRESS}" -u "${MYSQL_USERNAME}" --batch --connect-timeout=10 --execute="SHOW DATABASES;" | grep --silent 'mysql'; then
      echo 'MariaDB MySQL API usable'
      return 0
    else
      echo 'MariaDB MySQL API not usable'
      return 1
    fi
  else
    echo 'MariaDB MySQL API not usable'
    return 1
  fi
}

while ! checkdblogon;
do
  echo "Connection to ${MYSQL_ADDRESS} MySQL using ${MYSQL_USERNAME} credentials failed. Retrying in 5 seconds..."
  sleep 5
done
echo "Connection to MySQL successful"
