#!/usr/bin/env bash
set -e
set -x

psql `cat /etc/nova/nova.conf  | grep 'nova:' | grep postgresql | cut -d'=' -f2- | sed 's/\+psycopg2//' | sed 's/?.*//' | xargs` <<-EOT
UPDATE services SET deleted=id, deleted_at=now() WHERE updated_at IS NULL OR updated_at < now() - interval '30 minutes';
UPDATE compute_nodes
  SET service_id=(
    SELECT id FROM services WHERE services.host=compute_nodes.host AND deleted=0 ORDER BY updated_at DESC LIMIT 1)
    WHERE deleted=0 AND service_id IS NULL;
UPDATE compute_nodes SET deleted_at=now(), deleted=id WHERE service_id IS NULL;
EOT

if ! psql -lqt postgresql://{{ include "cell0_db_path" . }} | cut -d \| -f 1 | grep {{.Values.cell0dbName}}; then 
  echo Cell0 not found, createing cell0 database
  psql postgresql://{{.Values.postgresql.user}}:{{.Values.postgresql.postgresPassword}}@{{.Chart.Name}}-postgresql.{{include "svc_fqdn" .}}:5432 <<-EOT
CREATE DATABASE {{.Values.cell0dbName}};
CREATE ROLE {{.Values.cell0dbUser}} WITH ENCRYPTED PASSWORD '{{.Values.cell0dbPassword | default .Values.apidbPassword}}' LOGIN;
GRANT ALL PRIVILEGES ON DATABASE {{.Values.cell0dbName}} TO {{.Values.cell0dbUser}};
EOT
  nova-manage cell_v2 map_cell0 --database_connection postgresql+psycopg2://{{ include "cell0_db_path" . }} || true
fi

{{ $image := printf "%s" .Values.imageVersion}}
{{ if contains "pike" $image }} # Cell setup with Pike
# Upgrade to newton
nova-manage api_db sync --version 29 || true
nova-manage db sync --version 334 || true
echo 'Ignore errors due to online data migration'
nova-manage db online_data_migrations

# Create Cells if on pike, rerunning this doesn't break anything 
nova-manage cell_v2 discover_hosts
nova-manage cell_v2 simple_cell_setup
{{ end }}

# Finish upgrade
nova-manage api_db sync
nova-manage db sync
nova-manage db null_instance_uuid_scan --delete

# online data migration run by online-migration-job