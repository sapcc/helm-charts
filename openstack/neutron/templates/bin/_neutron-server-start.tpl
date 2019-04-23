#!/var/lib/openstack/bin/dumb-init bash

set -e

. /container.init/common.sh



function process_config {
    mkdir -p /etc/neutron/plugins/cisco
    mkdir -p /etc/neutron/plugins/ml2

    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/api-paste.ini  /etc/neutron/api-paste.ini
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/neutron-lbaas.conf /etc/neutron/neutron-lbaas.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2-conf.ini

    cp /neutron-etc-region/ml2-conf-aci.ini  /etc/neutron/plugins/ml2/ml2-conf-aci.ini

    cp /neutron-etc-vendor/ml2-conf-arista.ini  /etc/neutron/plugins/ml2/ml2-conf-arista.ini
    cp /neutron-etc-vendor/ml2-conf-manila.ini  /etc/neutron/plugins/ml2/ml2-conf-manila.ini
    cp /neutron-etc-vendor/ml2-conf-f5.ini  /etc/neutron/plugins/ml2/ml2-conf-f5.ini
    cp /neutron-etc-vendor/ml2-conf-asr1k.ini  /etc/neutron/plugins/ml2/ml2-conf-asr1k.ini

    cp /neutron-etc/neutron-policy.json  /etc/neutron/policy.json
    cp /neutron-etc/rootwrap.conf  /etc/neutron/rootwrap.conf

    {{- if .Values.audit.enabled }}
    cp /neutron-etc/neutron_audit_map.yaml /etc/neutron/neutron_audit_map.yaml
    {{- end }}

    {{- if .Values.watcher.enabled }}
    cp /neutron-etc/watcher.yaml /etc/neutron/watcher.yaml
    {{- end }}

    {{- if .Values.bgp_vpn.enabled }}
    cp /neutron-etc/networking-bgpvpn.conf /etc/neutron/networking-bgpvpn.conf
    {{- end }}

}

function _start_application {
    exec neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/neutron-lbaas.conf --config-file /etc/neutron/plugins/ml2/ml2-conf.ini  --config-file /etc/neutron/plugins/ml2/ml2-conf-f5.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-aci.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-manila.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-arista.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-asr1k.ini {{- if .Values.bgp_vpn.enabled }} --config-file /etc/neutron/networking-bgpvpn.conf{{- end }}
}

process_config
start_application
