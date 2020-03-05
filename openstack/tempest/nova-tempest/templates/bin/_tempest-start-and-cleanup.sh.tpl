#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {
  
  echo "Run cleanup"

  # Grep all servers and put into list
  COUNTER=0
  for user in nova-tempestuser1 nova-tempestuser2 nova-tempestuser3 nova-tempestuser4 nova-tempestuser5 nova-tempestuser6 nova-tempestuser7 nova-tempestuser8 nova-tempestuser9 nova-tempestuser10 nova-tempestuser11 nova-tempestuser12 nova-tempestuser13 nova-tempestuser14 nova-tempestuser15 nova-tempestuser16 nova-tempestuser17 nova-tempestuser18; do
    let COUNTER++
    export OS_USERNAME=$user
    TEMPESTPROJECT=nova-tempest$COUNTER
    export OS_TENANT_NAME=$TEMPESTPROJECT
    export OS_PROJECT_NAME=$TEMPESTPROJECT
    for server in $(openstack server list | awk 'NR > 3 { print $2 }' | head -n -1); do openstack server delete ${server}; done
  done

  COUNTER=0
  for user in nova-tempestadmin1 nova-tempestadmin2 nova-tempestadmin3 nova-tempestadmin4 nova-tempestadmin5 nova-tempestadmin6 nova-tempestadmin7 nova-tempestadmin8; do
    let COUNTER++
    export OS_USERNAME=$user
    TEMPESTPROJECT=nova-tempest-admin$COUNTER
    export OS_TENANT_NAME=$TEMPESTPROJECT
    export OS_PROJECT_NAME=$TEMPESTPROJECT
    for server in $(openstack server list | awk 'NR > 3 { print $2 }' | head -n -1); do openstack server delete ${server}; done
  done
    
}

{{- include "tempest-base.function_main" . }}

main
