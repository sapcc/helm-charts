#!/var/lib/openstack/bin/dumb-init bash

set -e

. /container.init/common.sh



function process_config {
    mkdir -p /etc/neutron/plugins/cisco
    mkdir -p /etc/neutron/plugins/ml2

    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/api-paste.ini  /etc/neutron/api-paste.ini
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/neutron-lbaas.conf /etc/neutron/neutron_lbaas.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini

    cp /neutron-etc-region/ml2-conf-aci.ini  /etc/neutron/plugins/ml2/ml2-conf-aci.ini

    cp /neutron-etc-vendor/ml2-conf-arista.ini  /etc/neutron/plugins/ml2/ml2_conf_arista.ini
    cp /neutron-etc-vendor/ml2-conf-manila.ini  /etc/neutron/plugins/ml2/ml2_conf_manila.ini
    cp /neutron-etc-vendor/ml2-conf-asr.ini  /etc/neutron/plugins/ml2/ml2_conf_asr.ini
    cp /neutron-etc-vendor/ml2-conf-f5.ini  /etc/neutron/plugins/ml2/ml2_conf_f5.ini
    cp /neutron-etc-vendor/ml2-conf-asr1k.ini  /etc/neutron/plugins/ml2/ml2_conf_asr1k.ini

    cp /neutron-etc/neutron-policy.json  /etc/neutron/policy.json
    cp /neutron-etc/rootwrap.conf  /etc/neutron/rootwrap.conf


    cp /neutron-etc-vendor/cisco-device-manager-plugin.ini   /etc/neutron/plugins/cisco/cisco_device_manager_plugin.ini
    cp /neutron-etc-vendor/cisco-router-plugin.ini   /etc/neutron/plugins/cisco/cisco_router_plugin.ini

    {{- if .Values.audit.enabled }}
    cp /neutron-etc/neutron_audit_map.yaml /etc/neutron/neutron_audit_map.yaml
    {{- end }}

    {{- if .Values.watcher.enabled }}
    cp /neutron-etc/watcher.yaml /etc/neutron/watcher.yaml
    {{- end }}
}

function _start_application {
    exec neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/neutron_lbaas.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini  --config-file /etc/neutron/plugins/ml2/ml2_conf_f5.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-aci.ini --config-file /etc/neutron/plugins/ml2/ml2_conf_asr.ini --config-file /etc/neutron/plugins/ml2/ml2_conf_manila.ini --config-file /etc/neutron/plugins/ml2/ml2_conf_arista.ini --config-file /etc/neutron/plugins/ml2/ml2_conf_asr1k.ini --config-file /etc/neutron/plugins/cisco/cisco_device_manager_plugin.ini --config-file /etc/neutron/plugins/cisco/cisco_router_plugin.ini
}

process_config
start_application
