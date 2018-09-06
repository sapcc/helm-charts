#!/usr/bin/env bash
set -e
set -x
uname
whoami

mkdir -p /var/lib/apt/lists/partial
apt update || true
apt-get -y install postgresql-client postgresql || true
export PGPASSWORD="{{.Values.postgresql.postgresPassword}}"
PATH=$PATH:/usr/lib/postgresql/9.5/bin
export PATH

echo " - Dumping running database"
mkdir -p /tmp/novadb
pg_dump -U {{.Values.postgresql.user}} -h {{.Chart.Name}}-postgresql.{{include "svc_fqdn" .}} nova > /tmp/nova.sql
pg_dump -U {{.Values.postgresql.user}} -h {{.Chart.Name}}-postgresql.{{include "svc_fqdn" .}} nova_api > /tmp/nova_api.sql

sudo -u postgres mkdir -p /var/run/postgresql/9.5-main.pg_stat_tmp/
sudo -u postgres /usr/lib/postgresql/9.5/bin/pg_ctl -D /etc/postgresql/9.5/main start
sleep 5
sudo -u postgres createuser -s root
psql postgres -c "CREATE USER nova WITH PASSWORD 'test';"
psql postgres -c "CREATE USER nova_API WITH PASSWORD 'test';"
createdb -O nova nova
createdb -O nova_api nova_api
psql nova < /tmp/nova.sql
psql nova_api < /tmp/nova_api.sql


mkdir -p /etc/nova
cat <<EOT >> /etc/nova/nova.conf
[DEFAULT]

[database]
connection = postgresql+psycopg2://nova:test@localhost/nova
[api_database]
connection = postgresql+psycopg2://nova_api:test@localhost/nova_api

EOT

psql postgres <<-EOT
CREATE DATABASE nova_cell0;
CREATE ROLE nova_cell0 WITH ENCRYPTED PASSWORD 'test' LOGIN;
GRANT ALL PRIVILEGES ON DATABASE nova_cell0 TO nova_cell0;
EOT
nova-manage cell_v2 map_cell0 --database_connection postgresql+psycopg2://nova_cell0:test@localhost/nova_cell0

virtualenv /tmp/nova-pike
#curl -L https://github.com/openstack/nova/archive/16.1.6.tar.gz | tar -xzC /tmp/nova-pike
git clone --depth 1 -b stable/pike https://github.com/openstack/nova.git /tmp/nova-pike/nova
curl -L --output /tmp/nova-pike/upper-constraints.txt https://raw.githubusercontent.com/openstack/requirements/stable/pike/upper-constraints.txt
source /tmp/nova-pike/bin/activate
pip install -c /tmp/nova-pike/upper-constraints.txt -r /tmp/nova-pike/nova/requirements.txt /tmp/nova-pike/nova raven psycopg2

# Upgrade to pike
nova-manage api_db sync --version 29 || true
nova-manage db sync --version 362 || true
echo 'Ignore errors due to online data migration'
nova-manage db online_data_migrations

# Create fake cell
nova-manage cell_v2 create_cell test_cell --transport-url null://nada --database_connection null://nada
deactivate
rm -rf /tmp/nova-pike

# Finish upgrade with queens
nova-manage api_db sync
nova-manage db sync
nova-manage db online_data_migrations
nova-manage db null_instance_uuid_scan --delete

sudo -u postgres /usr/lib/postgresql/9.5/bin/pg_ctl -D /etc/postgresql/9.5/main stop
echo "----------------------------"
echo " Database Migration dry-run successfully done"

# online data migration run by online-migration-job
