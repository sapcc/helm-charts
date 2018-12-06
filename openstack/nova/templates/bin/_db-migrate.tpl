#!/usr/bin/env bash
set -e
set -x

{{- if hasPrefix "queens" .Values.imageVersion }}
NOVA_VERSION=$(nova-manage db version)

if [ $NOVA_VERSION -eq '321' ]; then

    nova-manage cell_v2 map_cell0 --database_connection postgresql+psycopg2://{{ include "cell0_db_path" . }} || true

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

    # Create Cells if on pike, rerunning this doesn't break anything
    nova-manage cell_v2 discover_hosts
    nova-manage cell_v2 simple_cell_setup
    deactivate
    rm -rf /tmp/nova-pike

fi
{{ end }}
{{- end }}

# Finish upgrade with queens
nova-manage api_db sync
nova-manage db sync
nova-manage db null_instance_uuid_scan --delete

# online data migration run by online-migration-job
