#!/usr/bin/env bash

set -e

. /container.init/common.sh

function process_config {
    mkdir -p /etc/neutron/plugins/cisco

    cp /neutron-etc/neutron.conf /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf /etc/neutron/logging.conf
    cp /neutron-etc/neutron-policy.json  /etc/neutron/policy.json
    cp /neutron-etc/rootwrap.conf  /etc/neutron/rootwrap.conf

    cp /neutron-etc-asr1k/asr1k.conf /etc/neutron/asr1k.conf
}



function _start_application {
    exec asr1k-ml2-agent --config-file /etc/neutron/neutron.conf --config-dir /etc/neutron/secrets --config-file /etc/neutron/asr1k.conf
}


process_config
start_application


