#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_security_groups() {
  for secgroup in $(openstack security group list | grep -E "tempest-securitygroup|tempest_security_group" | awk '{ print $4 }');
  do
    echo "Security group $secgroup will be deleted";
    openstack security group delete ${secgroup};
  done
}

function cleanup_images() {
  for image in $(openstack image list -f value -c Name | grep tempest);
  do
    if [ "$image" = "ubuntu-20.04-tempest" ]; then
        echo "Tempest specific image will not deleted";
    else
        echo "Image $image will be deleted";
        openstack image delete ${image};
    fi
  done
}

function cleanup_fips_user() {
  # Delete all fips for nova user
  COUNTER=0
  for user in nova-tempestuser1 nova-tempestuser2 nova-tempestuser3 nova-tempestuser4 nova-tempestuser5 nova-tempestuser6 nova-tempestuser7 nova-tempestuser8 nova-tempestuser9 nova-tempestuser10 nova-tempestuser11 nova-tempestuser12 nova-tempestuser13 nova-tempestuser14 nova-tempestuser15 nova-tempestuser16 nova-tempestuser17 nova-tempestuser18; do
    let COUNTER++
    export OS_USERNAME=$user
    TEMPESTPROJECT=nova-tempest$COUNTER
    export OS_TENANT_NAME=$TEMPESTPROJECT
    export OS_PROJECT_NAME=$TEMPESTPROJECT
    for ip in $(openstack floating ip list | grep 10. | awk '{ print $2 }'); do openstack floating ip delete ${ip}; done
  done
}

function cleanup_fips_admin() {
  # Delete all fips for nova admin
  COUNTER=0
  for admin in nova-tempestadmin1 nova-tempestadmin2 nova-tempestadmin3 nova-tempestadmin4 nova-tempestadmin5 nova-tempestadmin6 nova-tempestadmin7 nova-tempestadmin8; do
    let COUNTER++
    export OS_USERNAME=$admin
    TEMPESTPROJECT=nova-tempest-admin$COUNTER
    export OS_TENANT_NAME=$TEMPESTPROJECT
    export OS_PROJECT_NAME=$TEMPESTPROJECT
    for ip in $(openstack floating ip list | grep 10. | awk '{ print $2 }'); do openstack floating ip delete ${ip}; done
  done
}

function cleanup_nova() {
    for i in $(seq 1 18); do
      export OS_USERNAME=nova-tempestuser${i}
      export OS_PROJECT_NAME=nova-tempest${i}
      cleanup_security_groups
      cleanup_images
    done

    for i in $(seq 1 8); do
      export OS_USERNAME=nova-tempestadmin${i}
      export OS_PROJECT_NAME=nova-tempest-admin${i}
      cleanup_security_groups
      cleanup_images
    done
}

function cleanup_tempest_leftovers() {
  
  echo "Run cleanup"

  delete_os_items() {
    os_item_type=$1
    for item_id in $(openstack $os_item_type list -f value -c ID); do
      openstack $os_item_type delete ${item_id}
    done
  }

  delete_tempest_os_items() {
    os_item_type=$1
    for i in $(seq 1 18); do
      export OS_USERNAME=nova-tempestuser${i}
      export OS_PROJECT_NAME=nova-tempest${i}
      delete_os_items "$os_item_type"
    done

    for i in $(seq 1 8); do
      export OS_USERNAME=nova-tempestadmin${i}
      export OS_PROJECT_NAME=nova-tempest-admin${i}
      delete_os_items "$os_item_type"
    done
  }

  # Delete types sequentially so that the deletion of servers in project 1 is
  # eventually completed by the time script gets to deleting ports in project 1
  delete_tempest_os_items "server"
  delete_tempest_os_items "port"
  delete_tempest_os_items "server group"
  cleanup_nova
  cleanup_fips_user
  cleanup_fips_admin
}

{{- include "tempest-base.function_main" . }}

main
