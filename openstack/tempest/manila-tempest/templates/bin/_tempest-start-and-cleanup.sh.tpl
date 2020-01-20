#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {

  echo "Run cleanup"

  export OS_USERNAME='tempestuser2'
  export OS_TENANT_NAME='tempest2'
  export OS_PROJECT_NAME='tempest2'
  for snap in $(manila snapshot-list | grep -E 'tempest' | awk '{ print $2 }'); do manila snapshot-force-delete ${snap}; done
  for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila force-delete ${share}; done
  for net in $(manila share-network-list | grep -E 'tempest|None' | awk '{ print $2 }'); do manila share-network-delete ${net}; done
  for ss in $(manila security-service-list --detailed 1 --columns "id,name,user"| grep -E 'tempest' | awk '{ print $2 }'); do manila security-service-delete ${ss}; done
  export OS_USERNAME='admin'
  export OS_TENANT_NAME='admin'
  export OS_PROJECT_NAME='admin'
  for snap in $(manila snapshot-list | grep -E 'tempest' | awk '{ print $2 }'); do manila snapshot-force-delete ${snap}; done
  for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila force-delete ${share}; done
  for ss in $(manila security-service-list --detailed 1 --columns "id,name,user"| grep -E 'tempest' | awk '{ print $2 }'); do manila security-service-delete ${ss}; done
  for type in $(manila type-list | grep -E 'tempest' | awk '{ print $2 }'); do manila type-delete ${type}; done
}

{{- include "tempest-base.function_main" . }}

main
