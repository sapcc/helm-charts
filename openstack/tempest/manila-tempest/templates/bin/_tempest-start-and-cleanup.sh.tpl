#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {

  echo "Run cleanup"

  export OS_USERNAME='tempestuser1'
  export OS_TENANT_NAME='tempest1'
  export OS_PROJECT_NAME='tempest1'

  share_network_id={{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.share_network_id }}
  alt_share_network_id={{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.alt_share_network_id }}
  admin_share_network_id={{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_share_network_id }}
  pre_created_share_networks=("$share_network_id" "$alt_share_network_id" "$admin_share_network_id")

  for snap in $(manila snapshot-list | grep -E 'tempest' | awk '{ print $2 }'); do manila snapshot-force-delete ${snap}; done
  for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila force-delete ${share}; done
  for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila reset-task-state ${share} && manila force-delete ${share}; done
  for net in $(manila share-network-list | grep -E 'tempest|None' | awk '{ print $2 }')
  do
    # don't delete pre-created share networks
    if [[ ! " ${pre_created_share_networks[@]} " =~ " ${net} " ]]; then
      manila share-network-delete ${net}
    fi
  done
  for ss in $(manila security-service-list --detailed 1 --columns "id,name,user"| grep -E 'tempest|None' | awk '{ print $2 }'); do manila security-service-delete ${ss}; done
  export OS_USERNAME='admin'
  export OS_TENANT_NAME='admin'
  export OS_PROJECT_NAME='admin'
  for snap in $(manila snapshot-list | grep -E 'tempest' | awk '{ print $2 }'); do manila snapshot-force-delete ${snap}; done
  for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila force-delete ${share}; done
  for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila reset-task-state ${share} && manila force-delete ${share}; done
  for ss in $(manila security-service-list --detailed 1 --columns "id,name,user"| grep -E 'tempest|None' | awk '{ print $2 }'); do manila security-service-delete ${ss}; done
  for type in $(manila type-list | grep -E 'tempest' | awk '{ print $2 }'); do manila type-delete ${type}; done
}

{{- include "tempest-base.function_main" . }}

cleanup_tempest_leftovers
main
