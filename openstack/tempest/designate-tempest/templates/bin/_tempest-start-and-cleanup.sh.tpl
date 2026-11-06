#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {
  echo "Install stable python-designateclient"
  pip install git+https://github.com/sapcc/python-designateclient.git@stable/2024.2-m3

  echo "Run cleanup"
  export OS_USERNAME=admin
  export OS_PROJECT_DOMAIN_NAME=tempest
  export OS_DOMAIN_NAME=tempest
  export OS_USER_DOMAIN_NAME=tempest

  # Zones left over by tempest, e.g.:
  #   testdomain.com.
  #   rand-1506668724.com.
  #   rand-test_share_imported_zone-1080999967.com.
  #   test_alt_list_shared_zone_exports-884344246.com.
  # i.e. name contains "testdomain", or starts with "rand"/"test" and ends with "-<number>.com."
  local ZONE_NAME_REGEX='(testdomain|^(rand|test)[a-z0-9_-]*-[0-9]+\.com\.?$)'

  local project zone_id zone_name zone_owner tld_id tld_name

  for project in admin tempest1 tempest2; do
    export OS_PROJECT_NAME=${project}
    if ! PROJECT_ID=$(openstack project show "${project}" -c id -f value) || [[ -z "${PROJECT_ID}" ]]; then
      echo "WARNING: cannot resolve project ${project}, skipping it"
      continue
    fi
    echo "Cleanup zones in project ${project} (${PROJECT_ID})"

    while read -r zone_id zone_name; do
      [[ -n "${zone_id}" ]] || continue
      [[ "${zone_name,,}" =~ ${ZONE_NAME_REGEX} ]] || continue

      # The zone list of a project also contains zones shared with it by other projects,
      # so a zone is deleted only if it is owned by the current project
      zone_owner=$(openstack zone show "${zone_id}" --sudo-project-id "${PROJECT_ID}" -c project_id -f value) || zone_owner=""
      if [[ "${zone_owner}" != "${PROJECT_ID}" ]]; then
        echo "Skip zone ${zone_name} (${zone_id}): owner is '${zone_owner}', not ${project}"
        continue
      fi

      echo "Delete zone ${zone_name} (${zone_id})"
      openstack zone delete "${zone_id}" --sudo-project-id "${PROJECT_ID}" --delete-shares > /dev/null \
        || echo "WARNING: failed to delete zone ${zone_name} (${zone_id})"
    done < <(openstack zone list --sudo-project-id "${PROJECT_ID}" -f value -c id -c name)
  done

  echo "Cleanup TLDs"
  while read -r tld_id tld_name; do
    [[ -n "${tld_id}" ]] || continue

    echo "Delete TLD ${tld_name} (${tld_id})"
    openstack tld delete "${tld_id}" \
      || echo "WARNING: failed to delete TLD ${tld_name} (${tld_id})"
  done < <(openstack tld list -f value -c id -c name)
}

{{- include "tempest-base.function_main" . }}

main