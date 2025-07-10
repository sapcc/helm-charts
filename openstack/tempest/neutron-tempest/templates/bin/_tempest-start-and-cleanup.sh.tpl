#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_ports_and_networks() {
      for network in $(openstack network list | grep -E "tempest-test-network" | awk '{ print $4 }');
      do
          for port in $(openstack port list --network $network | awk 'NR > 3 { print $2 }');
          do
              echo "Port $port will be disabled and deleted";
              device_owner=$(openstack port show $port -f value -c device_owner)
              if [[ $device_owner == "network:router_interface" ]]; then
                router_id=$(openstack port show $port -f value -c device_id);
                echo "Port ${port} will be removed from router $router_id";
                openstack router remove port ${router_id} ${port};
                echo "Router to delete $router_id";
                openstack router delete ${router_id}
              else
                openstack port set ${port} --disable --no-fixed-ip;
                openstack port delete ${port};
              fi
          done
          echo "Network $network will be deleted";
          openstack network delete $network;
      done
 for network in $(openstack network list | grep -oP "tempest-\w*[A-Z]+\S+");
 do
      for port in $(openstack port list --network $network | awk 'NR > 3 { print $2 }');
      do
          echo "Port $port will be disabled and deleted";
          device_owner=$(openstack port show $port -f value -c device_owner)
          if [[ $device_owner == "network:router_interface" ]]; then
            router_id=$(openstack port show $port -f value -c device_id);
            echo "Port ${port} will be removed from router $router_id";
            openstack router remove port ${router_id} ${port};
            echo "Router to delete $router_id";
            openstack router delete ${router_id}
          else
            openstack port set ${port} --disable --no-fixed-ip;
            openstack port delete ${port};
          fi

      done
      echo "Network $network will be deleted";
      openstack network delete $network;
 done
}

function cleanup_security_groups() {
  for secgroup in $(openstack security group list | awk 'NR > 3 { print $4 }' | grep tempest);
  do
    echo "Security group $secgroup will be deleted";
    openstack security group delete ${secgroup};
  done
}

function cleanup_address_groups() {
  for ag in $(openstack address group list -c Name -f value | grep tempest-test);
  do
    echo "Address group $ag will be deleted"
    openstack address group delete $ag
  done
}

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
    cleanup_ports_and_networks
    for subnet in $(openstack subnet list | grep -E "tempest-lb_member" | awk '{ print $4 }'); do echo Subnet ${subnet} will be deleted; openstack subnet delete ${subnet}; done
    for pool in $(openstack subnet pool list | grep -E "tempest" | awk '{ print $2 }'); do openstack subnet pool delete ${pool}; done
    for router in $(openstack router list | grep -E "tempest|abc" | awk '{ print $2 }'); do openstack router delete ${router}; done
    cleanup_ports_and_networks
    cleanup_security_groups
  done


  # Delete all networks, routers, subnets and subnet pools for Admin
  export OS_USERNAME='neutron-tempestadmin1'
  export OS_TENANT_NAME='neutron-tempest-admin1'
  export OS_PROJECT_NAME='neutron-tempest-admin1'
  cleanup_ports_and_networks
  cleanup_address_groups
  for subnet in $(openstack subnet list | grep -E "tempest-lb_member" | awk '{ print $4 }'); do echo Subnet ${subnet} will be deleted; openstack subnet delete ${subnet}; done
  for pool in $(openstack subnet pool list | grep -E "tempest" | awk '{ print $2 }'); do openstack subnet pool delete ${pool}; done
  for addscope in $(openstack address scope list | grep "tempest-\w*" |  awk '{ print $2 }'); do
    openstack address scope delete ${addscope}
  done
  for router in $(openstack router list | grep -E "tempest|abc" | awk '{ print $2 }'); do openstack router delete ${router}; done
  cleanup_ports_and_networks
  cleanup_security_groups
}

{{- include "tempest-base.function_main" . }}

main