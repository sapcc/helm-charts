#!/usr/bin/env bash

set -e

. /container.init/common.sh

function process_config {
    mkdir -p /etc/neutron/plugins/cisco

    cp /neutron-etc/neutron.conf /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf /etc/neutron/logging.conf
    cp /neutron-etc/neutron-policy.json  /etc/neutron/policy.json
    cp /neutron-etc/rootwrap.conf  /etc/neutron/rootwrap.conf

    cp /neutron-etc-vendor/cisco-cfg-agent.ini /etc/neutron/plugins/cisco/cisco_cfg_agent.ini
    cp /neutron-etc-vendor/cisco-device-manager-plugin.ini /etc/neutron/plugins/cisco/cisco_device_manager_plugin.ini
}



function _start_application {
    exec neutron-cisco-cfg-agent --config-file /etc/neutron/plugins/cisco/cisco_cfg_agent.ini --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/cisco/cisco_device_manager_plugin.ini --log-file /var/log/neutron/cisco-cfg-agent.log
}


process_config
start_application


