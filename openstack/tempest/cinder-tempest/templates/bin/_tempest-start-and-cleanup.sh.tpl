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
    for group_snap in $(openstack volume group snapshot list --os-volume-api-version 3.14 | grep -v -e ID -e '^+' | awk '{print $2;}'); do
      echo "Deleting group snapshot: ${group_snap}"
      openstack volume group snapshot delete ${group_snap} --os-volume-api-version 3.14
    done

    for backup in $(openstack volume backup list --all -f value -c ID -c Name | grep tempest | awk '{print $1}'); do
      echo "Deleting backup: ${backup}"
      if ! openstack volume backup delete ${backup} 2>/dev/null; then
        echo "Backup ${backup} stuck. Resetting state via OSC..."
        openstack volume backup set --state error ${backup}
        openstack volume backup delete ${backup}
      fi
    done

    for snapshot in $(openstack volume snapshot list --all -f value -c ID -c Name | grep tempest | awk '{print $1}'); do
      echo "Deleting snapshot: ${snapshot}"
      if ! openstack volume snapshot delete ${snapshot} 2>/dev/null; then
        echo "Snapshot ${snapshot} stuck. Resetting state via OSC..."
        openstack volume snapshot set --state error ${snapshot}
        openstack volume snapshot delete ${snapshot}
      fi
    done
  }

  delete_volumes() {
    for volume in $(openstack volume list --all -f value -c ID -c Name | grep tempest | awk '{print $1}'); do
      echo "Deleting volume: ${volume}"
      if ! openstack volume delete ${volume} 2>/dev/null; then
        echo "Volume ${volume} stuck. Forcing error state and detaching..."
        openstack volume set --state error ${volume}
        openstack volume set --detached ${volume}
        openstack volume delete ${volume}
      fi
    done
  }

  delete_groups() {
    # this will be called twice, because there are groups created from snapshot
    # which need to go before we can delete the snapshots in other groups
    for group in $(openstack volume group list --os-volume-api-version=3.13 | grep -v -e ID -e '^+' | awk '{print $2;}'); do
      openstack volume group delete --os-volume-api-version=3.13 --force ${group}
    done
  }

  delete_group_types() {
    for group_type in $(openstack volume group type list --os-volume-api-version 3.11 | grep -v -e ID -e '^+' | grep tempest | awk '{print $2;}'); do
      openstack volume group type delete --os-volume-api-version 3.11 ${group_type}
    done
  }

  delete_volume_types() {
    local vtypes=$(openstack volume type list -f value -c ID -c Name | grep -E 'tempest-|vol-type-for-' | awk '{print $1;}')
    local all_vols_with_types=$(openstack volume list --all-projects --long -f value -c ID -c "Type")
    for volume_type in $vtypes; do
      echo "Checking dependencies for volume type: ${volume_type}"
      local dependent_vols=$(echo "$all_vols_with_types" | grep "${volume_type}" | awk '{print $1}')

      if [ -n "$dependent_vols" ]; then
        for v_id in $dependent_vols; do
          echo "Force cleaning volume ${v_id} linked to type ${volume_type}"
          openstack volume set --state error ${v_id}
          openstack volume delete ${v_id}
        done
        sleep 2
      fi
      echo "Deleting volume type: ${volume_type}"
      openstack volume type delete ${volume_type}
    done
  }

  echo "Step 1: Cleanup dependencies (backups, snapshots, groups)"
  for i in $(seq 1 18); do
    export OS_USERNAME=nova-tempestuser${i}
    export OS_PROJECT_NAME=nova-tempest${i}
    delete_dependencies
    delete_groups
  done

  for i in $(seq 1 8); do
    export OS_USERNAME=nova-tempestadmin${i}
    export OS_PROJECT_NAME=nova-tempest-admin${i}
    delete_dependencies
    delete_groups
  done

  echo "Step 2: Cleanup volumes and volume types"
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
