#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {

  echo "Run cleanup"
  export OS_USERNAME=admin
  export OS_PROJECT_DOMAIN_NAME=tempest
  export OS_DOMAIN_NAME=tempest
  export OS_USER_DOMAIN_NAME=tempest

  for i in $(seq 1 2); do
      export OS_PROJECT_NAME=tempest${i}
      PROJECT_ID=$(openstack project show tempest${i} -c id -f value)
      for zone in $(openstack zone list --sudo-project-id $PROJECT_ID | grep -E "testdomain" | awk '{ print $2 }'); do
          openstack zone delete $zone --sudo-project-id $PROJECT_ID;
      done

      for tld in $(openstack tld list --sudo-project-id  $PROJECT_ID); do
          openstack tld delete $tld --sudo-project-id  $PROJECT_ID;
      done
  done

}

{{- include "tempest-base.function_main" . }}

main
