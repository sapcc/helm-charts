#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {
  
  echo "Run cleanup"

  # we delete the dependencies first and hope the time it takes to delete all
  # of them for all projects will give cinder enough time to actually delete
  # them before we try to delete the volumes. if that doesn't hold true, we
  # need to build some waiting function

  delete_dependencies() {
    for group_snap in $(cinder group-snapshot-list | grep -v -e ID -e '^+' | awk '{print $2;}'); do
      cinder group-snapshot-delete ${group_snap}
    done

    for backup in $(openstack volume backup list -f value -c ID); do
      openstack backup delete ${backup}
    done

    for snapshot in $(openstack volume snapshot list -f value -c ID); do
      openstack volume snapshot delete ${snapshot}
      if [ "$?" != "0" ]; then
        cinder group-snapshot-delete ${snapshot}
      fi
    done
  }

  delete_volumes() {
    for volume in $(openstack volume list -f value -c ID); do
      openstack volume delete ${volume}
      if [ "$?" != "0" ]; then
        # we try to delete again after setting the volume state to something
        # that should be deletable
        openstack volume set --state error ${volume}
        openstack volume delete ${volume}
      fi
    done
  }

  delete_groups() {
    # this will be called twice, because there are groups created from snapshot
    # which need to go before we can delete the snapshots in other groups
    for group in $(cinder group-list | grep -v -e ID -e '^+' | awk '{print $2;}'); do
      cinder group-delete --delete-volumes ${group}
    done
  }

  delete_group_types() {
    for group_type in $(cinder group-type-list | grep -v -e ID -e '^+' | grep tempest | awk '{print $2;}'); do
      cinder group-type-delete ${group_type}
    done
  }

  delete_volume_types() {
    for volume_type in $(openstack volume type list -f value | grep tempest- | awk '{print $1;}'); do
      openstack volume type delete ${volume_type}
    done
  }

  for i in $(seq 1 18); do
    export OS_USERNAME=nova-tempestuser${i}
    export OS_PROJECT_NAME=nova-tempest${i}
    delete_groups
    delete_dependencies
    delete_groups
  done

  for i in $(seq 1 8); do
    export OS_USERNAME=nova-tempestadmin${i}
    export OS_PROJECT_NAME=nova-tempest-admin${i}
    delete_groups
    delete_dependencies
    delete_groups
  done

  for i in $(seq 1 18); do
    export OS_USERNAME=nova-tempestuser${i}
    export OS_PROJECT_NAME=nova-tempest${i}
    delete_volumes
  done
  
  for i in $(seq 1 8); do
    export OS_USERNAME=nova-tempestadmin${i}
    export OS_PROJECT_NAME=nova-tempest-admin${i}
    delete_volumes
    delete_group_types
    delete_volume_types
  done
  
}

{{- include "tempest-base.function_main" . }}

main
