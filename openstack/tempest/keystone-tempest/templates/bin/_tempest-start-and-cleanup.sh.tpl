#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {
  
  echo "Run cleanup"
  unset OS_PROJECT_DOMAIN_NAME
  unset OS_PROJECT_NAME
  unset OS_TENANT_NAME
  unset OS_USERNAME
  unset OS_USER_DOMAIN_NAME

  export OS_USERNAME=admin
  export OS_PROJECT_DOMAIN_NAME=tempest
  export OS_USER_DOMAIN_NAME=tempest
  export OS_PROJECT_NAME=admin

  for service in $(openstack service list | grep -E 'tempest-service' | awk '{ print $2 }'); do openstack service delete ${service}; done
  for region in $(openstack region list | grep -E 'tempest-region' | awk '{ print $2 }'); do openstack region delete ${region}; done
  for domain in $(openstack domain list | grep -E 'tempest-test_domain' | awk '{ print $2 }'); do openstack domain set --disable ${domain}; openstack domain delete ${domain}; done
  for project in $(openstack project list --domain tempest | grep -oP "tempest-\w*[A-Z]+\S+"); do openstack --os-username=admin --os-user-domain-name=tempest --os-domain-name=tempest project delete ${project}; done
  for user in $(openstack user list --domain tempest | grep -oP "tempest-\w*[A-Z]+\S+"); do echo "Deleting user ${user}"; openstack --os-username=admin --os-user-domain-name=tempest --os-domain-name=tempest user delete --domain tempest ${user}; done

  # Reset tempestuser passwords after tests (sometimes it doesn't work from tempest code)
  openstack user set tempestuser1 --domain tempest --password={{ .Values.tempestAdminPassword | quote }}
  openstack user set tempestuser2 --domain tempest --password={{ .Values.tempestAdminPassword | quote }}
}

{{- include "tempest-base.function_main" . }}

main
