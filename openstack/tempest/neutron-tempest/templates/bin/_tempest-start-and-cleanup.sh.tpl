#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {
  
  echo "Run cleanup"

  # Subnet CIDR pattern from tempest.conf: https://docs.openstack.org/tempest/latest/sampleconf.html

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
    for ip in $(openstack floating ip list | grep 10. | awk '{ print $2 }'); do openstack floating ip delete ${ip}; done
    for network in $(openstack network list | awk 'NR > 3 { print $2 }' | head -n -1); do openstack network delete ${network}; done 
    for router in $(openstack router list | grep -E "tempest|test|abc" | awk '{ print $2 }'); do openstack router delete ${router}; done
  done

  # Delete all networks, routers and subnet pools for Admin
  export OS_USERNAME='neutron-tempestadmin1'
  export OS_TENANT_NAME='neutron-tempest-admin1'
  export OS_PROJECT_NAME='neutron-tempest-admin1'
  for network in $(openstack network list | grep -E "tempest" | awk '{ print $2 }'); do openstack network delete ${network}; done
  for pool in $(openstack subnet pool list | grep -E "tempest" | awk '{ print $2 }'); do openstack subnet pool delete ${pool}; done 
}

{{- include "tempest-base.function_main" . }}

main
