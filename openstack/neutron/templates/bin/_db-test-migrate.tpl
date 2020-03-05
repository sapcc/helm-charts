#!/usr/bin/env bash

echo "######### Testing migration to {{default "queens-20190318110549" .Values.imageVersionUpgrade}} #########"

set -x
apt-get update
apt-get install -y postgresql python-swiftclient
chmod 600 ~/.pgpass

latest=$(swift download db_backup $OS_REGION_NAME/monsoon3/neutron-postgresql/last_backup_timestamp -o -)
swift download db_backup $OS_REGION_NAME/monsoon3/neutron-postgresql/$latest/backup/pgsql/base/neutron.sql.gz -o /tmp/neutron.sql.gz
gunzip /tmp/neutron.sql.gz

/etc/init.d/postgresql start
export PGPASSWORD="neutron"
echo 'neutron' > ~/.pgpass

sudo -u postgres psql -c "create role root with login superuser password 'neutron';"
createdb -O root neutron

psql neutron < /tmp/neutron.sql
neutron-db-manage --database-connection postgresql+psycopg2://root:neutron@localhost:5432/neutron current --verbose
neutron-db-manage --database-connection postgresql+psycopg2://root:neutron@localhost:5432/neutron upgrade head