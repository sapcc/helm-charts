#!/bin/sh

set -x

start_rally_tests() {
    set -e

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

    # run the tempest tests for keystone
    rally verify start --concurrency 1 --detailed --pattern set=identity

    # evaluate the overall test result
    rally verify list --status failed | grep 'failed' && exit 1
}

cleanup_tempest_leftovers() {
    for service in $(openstack service list | grep -E 'tempest-service' | awk '{ print $2 }'); do openstack service delete ${service}; done
}

main() {
    start_rally_tests &
    wait $!
    exit_code=$?
    cleanup_tempest_leftovers
    return $exit_code
}

main
