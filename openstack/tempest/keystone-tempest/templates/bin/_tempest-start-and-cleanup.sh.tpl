#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {
  
  echo "Run cleanup"

  for service in $(openstack service list | grep -E 'tempest-service' | awk '{ print $2 }'); do openstack service delete ${service}; done
  for region in $(openstack region list | grep -E 'tempest-region' | awk '{ print $2 }'); do openstack region delete ${region}; done
  for project in $(openstack project list --domain tempest | grep -E 'tempest-Domains' | awk '{ print $2 }'); do openstack project delete ${project}; done
  for domain in $(openstack domain list | grep -E 'tempest-test_domain' | awk '{ print $2 }'); do openstack domain set --disable ${domain}; openstack domain delete ${domain}; done

}

{{- include "tempest-base.function_main" . }}

main
