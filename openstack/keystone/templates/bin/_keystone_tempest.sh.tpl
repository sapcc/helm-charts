#!/bin/sh

set -x

start_rally_tests() {
    set -e

    # ensure rally db is present
    rally db ensure

    # configure deployment for current region with existing users
    rally --debug deployment create --file /etc/keystone/rally_deployment_config.json --name rally_deployment

    # check if we can reach openstack endpoints
    rally --debug deployment check

    # create tempest verifier fetched from our repo
    rally --debug verify create-verifier --type tempest --name keystone-tempest-verifier --version 19.0.0

    # configure tempest verifier
    rally --debug verify configure-verifier --extend /etc/tempest/tempest.conf

    # run the tempest tests for keystone
    rally --debug verify start --concurrency 1 --detailed --pattern set=identity

    # evaluate the overall test result
    rally verify list --status failed | grep -c 'failed' && exit 1 || exit 0
}

cleanup_tempest_leftovers() {
    for service in $(openstack service list | grep -E 'tempest-service' | awk '{ print $2 }'); do openstack service delete ${service}; done
    for region in $(openstack region list | grep -E 'tempest-region' | awk '{ print $2 }'); do openstack region delete ${region}; done
}

main() {
    start_rally_tests &
    wait $!
    exit_code=$?
    cleanup_tempest_leftovers
    return $exit_code
}

main
