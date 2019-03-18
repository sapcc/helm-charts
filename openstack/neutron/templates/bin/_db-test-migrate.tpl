#!/usr/bin/env bash

echo "######### Testing migration to {{.Values.imageVersionUpgrade}} #########"

set -x
apt-get update
apt-get install -y postgresql
echo '{{ required "A valid .Values.global.dbPassword required!" .Values.global.dbPassword }}' > ~/.pgpass
export PGPASSWORD="{{ required "A valid .Values.global.dbPassword required!" .Values.global.dbPassword }}"
chmod 600 ~/.pgpass

if [ ! -f /tmp/neutron.sql ]; then
	pg_dump -h {{include "neutron_db_host" .}} -U {{ default .Release.Name .Values.global.dbUser }} -p {{.Values.global.postgres_port_public | default 5432}} neutron > /tmp/neutron.sql
fi

/etc/init.d/postgresql start
export PGPASSWORD="neutron"
echo 'neutron' > ~/.pgpass

sudo -u postgres psql -c "create role root with login superuser password 'neutron';"
createdb -O root neutron

psql neutron < /tmp/neutron.sql
psql neutron -c 'delete from portdnses'
neutron-db-manage --database-connection postgresql+psycopg2://root:neutron@localhost:5432/neutron current --verbose
neutron-db-manage --database-connection postgresql+psycopg2://root:neutron@localhost:5432/neutron upgrade head