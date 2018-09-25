#!/bin/sh

set -x

start_rally_tests() {
    set -e

    # ensure rally db is present
    rally db ensure

    # configure deployment for current region with existing users
    rally deployment create --file /etc/keystone/rally_deployment_config.json --name rally_deployment

    # check if we can reach openstack endpoints
    rally deployment check

    # create tempest verifier fetched from our repo
    rally verify create-verifier --type tempest --name keystone-tempest-verifier --version 19.0.0

    # configure tempest verifier
    rally verify configure-verifier --extend /etc/tempest/tempest.conf --show

    # run the tempest tests for keystone
    rally verify start --concurrency 1 --detailed --pattern set=identity

    # evaluate the overall test result
    rally verify list --status failed | grep -c 'failed' && exit 1 || exit 0
}

cleanup_tempest_leftovers() {
    for service in $(openstack service list | grep -E 'tempest-service' | awk '{ print $2 }'); do openstack service delete ${service}; done
    for region in $(openstack region list | grep -E 'tempest-region' | awk '{ print $2 }'); do openstack region delete ${region}; done
    for project in $(openstack project list --domain tempest | grep -E 'tempest-Domains' | awk '{ print $2 }'); do openstack project delete ${project}; done
    for domain in $(openstack domain list | grep -E 'tempest-test_domain' | awk '{ print $2 }'); do openstack domain delete ${domain}; done
}

main() {
    start_rally_tests &
    wait $!
    exit_code=$?
    cleanup_tempest_leftovers
    return $exit_code
}

main
