#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {

  echo "Run cleanup"

  share_network_id={{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.share_network_id }}
  alt_share_network_id={{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.alt_share_network_id }}
  admin_share_network_id={{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_share_network_id }}
  pre_created_share_networks=("$share_network_id" "$alt_share_network_id" "$admin_share_network_id")

  for i in $(seq 1 2); do
      export OS_USERNAME=manila-tempestuser${i}
      export OS_TENANT_NAME=tempest${i}
      export OS_PROJECT_NAME=tempest${i}
      for snap in $(manila snapshot-list | grep -E 'tempest' | awk '{ print $2 }'); do manila snapshot-delete ${snap}; done
      for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila reset-state ${share} && manila delete ${share}; done
      for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila reset-task-state ${share} && manila delete ${share}; done
      for net in $(manila share-network-list | grep -E 'tempest|None' | awk '{ print $2 }')
      do
        # don't delete pre-created share networks
        if [[ ! " ${pre_created_share_networks[@]} " =~ " ${net} " ]]; then
          manila share-network-delete ${net}
        fi
      done
      for ss in $(manila security-service-list --detailed 1 --columns "id,name,user"| grep -E 'tempest|None' | awk '{ print $2 }'); do manila security-service-delete ${ss}; done
  done

  export OS_USERNAME='admin'
  export OS_TENANT_NAME='admin'
  export OS_PROJECT_NAME='admin'
  for snap in $(manila snapshot-list | grep -E 'tempest' | awk '{ print $2 }'); do manila snapshot-delete ${snap}; done
  for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila reset-state ${share} && manila delete ${share}; done
  for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila reset-task-state ${share} && manila delete ${share}; done
  for ss in $(manila security-service-list --detailed 1 --columns "id,name,user"| grep -E 'tempest|None' | awk '{ print $2 }'); do manila security-service-delete ${ss}; done
  for group-type in $(manila share-group-type-list | grep -E 'tempest' | awk '{ print $2 }'); do manila share-group-type-delete ${group-type}; done
  for type in $(manila type-list | grep -E 'tempest' | awk '{ print $2 }'); do manila type-delete ${type}; done
  for net in $(manila share-network-list | grep -E 'tempest|None' | awk '{ print $2 }')
  do
    # don't delete pre-created share networks
    if [[ ! " ${pre_created_share_networks[@]} " =~ " ${net} " ]]; then
      manila share-network-delete ${net}
    fi
  done

}

{{- include "tempest-base.function_main" . }}

cleanup_tempest_leftovers
main
