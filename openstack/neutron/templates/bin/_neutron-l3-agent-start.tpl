#!/usr/bin/env bash

set -e

. /container.init/common.sh

function process_config {
    mkdir -p  /etc/neutron/plugins/ml2/
    mkdir -p  /etc/neutron/rootwrap.d/

    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini
    cp /neutron-etc/l3-agent.ini  /etc/neutron/l3_agent.ini
    cp /neutron-etc/rootwrap.conf /etc/neutron/rootwrap.conf
    cp /neutron-etc/l3.filters    /etc/neutron/rootwrap.d/l3.filters
    cp /neutron-etc/sudoers       /etc/sudoers
}



function start_application {
    until ! pgrep -f /var/lib/openstack/bin/neutron-l3-agent; do
      echo "Waiting to be the only highlander"
      sleep 5
    done
    touch /var/lib/neutron/neutron-l3-agent-ready

    exec  neutron-l3-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/l3_agent.ini --config-file /etc/neutron/plugins/ml2/ml2_conf.ini
}

process_config

start_application


