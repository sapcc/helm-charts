#!/usr/bin/env bash

set -e
set -x

function start_rally_tests {
    # ensure rally db is present
    rally db ensure

    # configure deployment for current region with existing users
    rally deployment create --file /etc/keystone/tempest_deployment_config.json --name tempest_deployment

    # check if we can reach openstack endpoints
    rally deployment check

    # create tempest verifier fetched from our repo
    rally verify create-verifier --type tempest --name keystone-tempest-verifier --system-wide --source https://github.com/sapcc/tempest --version ccloud

    # configure tempest verifier
    rally verify configure-verifier --extend /etc/tempest/tempest.conf

    # run the actual tempest api tests for keystone
    rally verify start --concurrency 1 --detailed --pattern tempest.api.identity.v3.
    rally verify start --concurrency 1 --detailed --pattern tempest.api.identity.admin.v3.
    #rally verify start --concurrency 1 --detailed --pattern keystone_tempest_plugin.
}

start_rally_tests
