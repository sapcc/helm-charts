#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_pools_and_members() {
  for pool in $(openstack loadbalancer pool list | grep -E "tempest-lb" | awk '{ print $4 }');
  do
      for member in $(openstack loadbalancer member list  $pool | grep -E "tempest-lb" | awk 'NR > 3 { print $2 }');
      do
          echo "Loadbalancer member $member will be  deleted";
          openstack loadbalancer member delete ${pool} ${member};
      done
      echo "Loadbalancer pool $pool will be deleted";
      openstack loadbalancer pool delete ${pool};
  done
}

function cleanup_ports_and_networks() {
  for network in $(openstack network list | grep -E "tempest-lb_member" | awk '{ print $4 }');
  do
      for port in $(openstack port list --network $network | awk 'NR > 3 { print $2 }');
      do
          echo "Port $port will be disabled and deleted";
          openstack port set ${port} --disable --no-fixed-ip && openstack port delete ${port};
      done
      echo "Network $network will be deleted";
      openstack network delete $network;
  done
}

function cleanup_tempest_leftovers() {

  echo " ============ Fetching Tempest logs ============ "
  TEMPEST_LOG_FILE=$(find /home/rally/.rally/verification -iname tempest.log)
  cat $TEMPEST_LOG_FILE

  echo " ============ Running cleanup ============ "
  # Delete loadbalancers, lb flavors, pools, members for Admin
  export OS_USERNAME='neutron-tempestadmin1'
  export OS_TENANT_NAME='neutron-tempest-admin1'
  export OS_PROJECT_NAME='neutron-tempest-admin1'
  cleanup_pools_and_members
  cleanup_ports_and_networks
  for server in $(openstack server list --all | grep -E "tempest-lb_member" | grep -v -e ID -e '^+' | awk '{print $2;}'); do echo server ${server} will be deleted; openstack server delete ${server}; done
  for lb in $(openstack loadbalancer list | grep -E "tempest-lb_member" | awk '{ print $4 }'); do echo loadbalancer ${lb} will be deleted; openstack loadbalancer delete ${lb}; done
  for flavor in $(openstack loadbalancer flavor list | grep -E "tempest-lb" | awk '{ print $4 }'); do echo flavor ${flavor} will be deleted; openstack loadbalancer flavor delete ${flavor}; done
  for subnet in $(openstack subnet list | grep -E "tempest-lb_member" | awk '{ print $4 }'); do echo Subnet ${subnet} will be deleted; openstack subnet delete ${subnet}; done
  for secgroup in $(openstack security group list | grep -oP "tempest-\w*[A-Z]+\S+"); do openstack security group delete ${secgroup}; done
}

{{- include "tempest-base.function_main" . }}

main
