#!/usr/bin/env bash

set -xo pipefail

function start_tempest_tests {

  echo -e "\n === CONFIGURING TEMPEST === \n"

  # ensure rally db is present
  rally db ensure

  # configure deployment for current region with existing users
  rally deployment create --file /neutron-etc-tempest/tempest_deployment_config.json --name tempest_deployment

  # check if we can reach openstack endpoints
  rally deployment check

  # create tempest verifier fetched from our repo
  rally --debug verify create-verifier --type tempest --name neutron-tempest-verifier --system-wide --source https://github.com/sapcc/tempest --version ccloud

  # configure tempest verifier taking into account the auth section values provided in tempest_extra_options file
  rally --debug verify configure-verifier --extend /neutron-etc-tempest/tempest_extra_options

  # run the actual tempest tests for neutron
  echo -e "\n === STARTING TEMPEST TESTS FOR neutron === \n"
  rally --debug verify start --concurrency 4 --detailed --pattern neutron_tempest_plugin.api --skip-list /neutron-etc-tempest/tempest_skip_list.yaml

  # generate html report
  rally verify report --type html --to /tmp/report.html
}

function cleanup_tempest_leftovers() {

  # Subnet CIDR pattern from tempest.conf: https://docs.openstack.org/tempest/latest/sampleconf.html

  # Due to a clean up bug we need to clean up ourself the ports, networks and routers: https://bugs.launchpad.net/neutron/+bug/1759321

  # Grep all ports and put in a list, only IPv4  
  COUNTER=0
  for user in neutron-tempestuser1 neutron-tempestuser2 neutron-tempestuser3 neutron-tempestuser4 neutron-tempestuser5 neutron-tempestuser6 neutron-tempestuser7 neutron-tempestuser8 neutron-tempestuser9 neutron-tempestuser10; do
    let COUNTER++
    export OS_USERNAME=$user
    TEMPESTPROJECT=neutron-tempest$COUNTER
    export OS_TENANT_NAME=$TEMPESTPROJECT
    export OS_PROJECT_NAME=$TEMPESTPROJECT
    openstack port list | grep "ip_address='10.199.0." | grep -E "ACTIVE|DOWN" | awk '{ print $2 }' >> /tmp/myList.txt
  done

  # grep all ports from admin and put in a list, only IPv4
  COUNTER=0
  for user in neutron-tempestadmin1 neutron-tempestadmin2 neutron-tempestadmin3 neutron-tempestadmin4; do
    let COUNTER++
    export OS_USERNAME=$user
    TEMPESTPROJECT=neutron-tempest-admin$COUNTER
    export OS_TENANT_NAME=$TEMPESTPROJECT
    export OS_PROJECT_NAME=$TEMPESTPROJECT
    openstack port list | grep "ip_address='10.199.0." | grep -E "ACTIVE|DOWN" | awk '{ print $2 }' >> /tmp/myList.txt
  done
  
  # sort unique the list
  sort -u /tmp/myList.txt > /tmp/mySortedList.txt
  # disable and remove ip from the ports and delete all ports as admin
  while read port; do openstack port set ${port} --disable --no-fixed-ip && openstack port delete ${port}; done < /tmp/mySortedList.txt

  # Delete all networks and routers
  COUNTER=0
  for user in neutron-tempestuser1 neutron-tempestuser2 neutron-tempestuser3 neutron-tempestuser4 neutron-tempestuser5 neutron-tempestuser6 neutron-tempestuser7 neutron-tempestuser8 neutron-tempestuser9 neutron-tempestuser10; do
    let COUNTER++
    export OS_USERNAME=$user
    TEMPESTPROJECT=neutron-tempest$COUNTER
    export OS_TENANT_NAME=$TEMPESTPROJECT
    export OS_PROJECT_NAME=$TEMPESTPROJECT
    for network in $(openstack network list | grep -E "tempest|test|newnet|smoke-network" | awk '{ print $2 }'); do openstack network delete ${network}; done 
    for router in $(openstack router list | grep -E "tempest|test|abc" | awk '{ print $2 }'); do openstack router delete ${router}; done
  done

  # Delete all networks and routers for Admin
  export OS_USERNAME='neutron-tempestadmin1'
  export OS_TENANT_NAME='neutron-tempest-admin1'
  export OS_PROJECT_NAME='neutron-tempest-admin1'
  for network in $(openstack network list | grep -E "tempest" | awk '{ print $2 }'); do openstack network delete ${network}; done 
}

main() {
  start_tempest_tests
  TEMPEST_EXIT_CODE=$?
  cleanup_tempest_leftovers
  CLEANUP_EXIT_CODE=$?
  exit $(($TEMPEST_EXIT_CODE + $CLEANUP_EXIT_CODE))
}

main
