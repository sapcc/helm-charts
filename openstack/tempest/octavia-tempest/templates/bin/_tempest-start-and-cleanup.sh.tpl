#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {

  echo " ============ Fetching Tempest logs ============ "
  TEMPEST_LOG_FILE=$(find /home/rally/.rally/verification -iname tempest.log)
  cat $TEMPEST_LOG_FILE

  echo " ============ Running cleanup ============ "
  for i in $(seq 1 8); do
      export OS_USERNAME=neutron-tempestuser${i}
      export OS_PROJECT_NAME=neutron-tempest${i}
      # for lb in $(openstack loadbalancer list --project OS_PROJECT_NAME -f json | jq -r .[].id); do openstack loadbalancer --project $OS_PROJECT_NAME delete $lb; done
  done
}

{{- include "tempest-base.function_main" . }}

main
