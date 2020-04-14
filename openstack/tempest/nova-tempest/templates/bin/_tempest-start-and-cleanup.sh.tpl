#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

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
  delete_tempest_os_items "security group"
}

{{- include "tempest-base.function_main" . }}

main
