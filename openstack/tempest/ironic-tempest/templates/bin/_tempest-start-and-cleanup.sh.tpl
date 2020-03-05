#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {
  
  # Delete all nodes, created by tempest which have not been cleaned!
  export OS_USERNAME=neutron-tempestadmin1
  TEMPESTPROJECT=neutron-tempest-admin1
  export OS_TENANT_NAME=$TEMPESTPROJECT
  export OS_PROJECT_NAME=$TEMPESTPROJECT
  openstack baremetal node list -f value -c UUID -c Name -c 'Instance UUID' -c 'Provisioning State' | awk 'BEGIN { FS=" "} { if ($2 == "None") system("openstack baremetal node maintenance set "$1" && openstack baremetal node delete "$1) }'
  
}

{{- include "tempest-base.function_main" . }}

main
