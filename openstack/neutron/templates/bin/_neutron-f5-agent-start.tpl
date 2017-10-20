#!/var/lib/openstack/bin/dumb-init bash

set -e

. /container.init/common.sh

function process_config {
    mkdir -p /etc/neutron/services/f5/esd

    patch /var/lib/openstack/local/lib/python2.7/site-packages/f5/bigip/__init__.py /f5-patches/bigip-init.diff
    patch /var/lib/openstack/local/lib/python2.7/site-packages/requests/sessions.py /f5-patches/sessions.diff ||
        patch /usr/local/lib/python2.7/dist-packages/requests/sessions.py /f5-patches/sessions.diff

    cp /neutron-etc/neutron.conf /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/neutron-policy.json  /etc/neutron/policy.json
    cp /neutron-etc/neutron-lbaas.conf /etc/neutron/neutron_lbaas.conf
    cp /neutron-etc/rootwrap.conf  /etc/neutron/rootwrap.conf
    cp /f5-etc/f5-oslbaasv2-agent.ini /etc/neutron/f5-oslbaasv2-agent.ini
    cp /f5-etc/esd.json /etc/neutron/services/f5/esd/esd.json
}

function _start_application {
    exec f5-oslbaasv2-agent --config-file /etc/neutron/f5-oslbaasv2-agent.ini --config-file /etc/neutron/neutron.conf
}

process_config
start_application
