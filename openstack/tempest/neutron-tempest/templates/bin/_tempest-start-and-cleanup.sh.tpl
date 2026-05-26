#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

# Remove a single port safely, handling router_interface ownership
function remove_port() {
  local port=$1
  local device_owner
  local router_id

  device_owner=$(openstack port show "$port" -f value -c device_owner 2>/dev/null)

  if [[ "$device_owner" == "network:router_interface" || \
        "$device_owner" == "network:router_interface_distributed" ]]; then
    router_id=$(openstack port show "$port" -f value -c device_id 2>/dev/null)
    echo "Port ${port} is a router interface (router=${router_id})"

    if [[ -n "$router_id" && "$router_id" != "None" ]]; then
      local router_name
      router_name=$(openstack router show "$router_id" -f value -c name 2>/dev/null)
      if [[ "$router_name" != *tempest* ]]; then
        echo "WARN: port ${port} is attached to non-tempest router \'${router_name}\' (${router_id}) — skipping"
      else
        echo "Removing interface ${port} from router ${router_id} (${router_name})"
        openstack router remove port "${router_id}" "${port}" || \
          echo "WARN: could not remove port ${port} from router ${router_id}"
      fi
    else
      # Orphaned router interface: router was deleted but port survived.
      # Clear device_owner via admin so the port becomes deletable.
      echo "WARN: port ${port} has no valid router (device_id='${router_id}'), clearing device_owner"
      openstack port set "${port}" --device-owner "" 2>/dev/null || true
      openstack port delete "${port}" || \
        echo "WARN: could not force-delete orphaned router port ${port}"
    fi

  elif [[ "$device_owner" == network:dhcp* ]]; then
    # DHCP ports cannot be deleted via port API directly; skip them —
    # they are cleaned up automatically when the network is removed.
    echo "Skipping DHCP port ${port} (will be removed with network)"

  else
    openstack port set "${port}" --disable --no-fixed-ip 2>/dev/null || true
    openstack port delete "${port}" || \
      echo "WARN: could not delete port ${port}"
  fi
}

# Clean up all tempest networks matched by a grep pattern.
# Usage: cleanup_ports_and_networks <grep_pattern>
function cleanup_ports_and_networks() {
  local pattern=${1:-"tempest-test-network"}

  local network_ids
  network_ids=$(openstack network list -f value -c ID -c Name \
                  | grep -E "$pattern" | awk '{ print $1 }')

  for network_id in $network_ids; do
    local network_name
    network_name=$(openstack network show "$network_id" -f value -c name 2>/dev/null \
                   || echo "$network_id")
    echo "Processing network: ${network_name} (${network_id})"

    local router_ports
    router_ports=$(openstack port list --network "$network_id" -f value -c ID -c device_owner \
                     | grep -E "network:router_interface" | awk '{ print $1 }')
    local router_port_count
    router_port_count=$(echo "$router_ports" | grep -c . || true)
    echo "Removing ${router_port_count} router interface port(s) in ${network_name}"
    for port in $router_ports; do
      remove_port "$port"
    done

    local all_port_ids
    all_port_ids=$(openstack port list --network "$network_id" -f value -c ID)
    for port in $all_port_ids; do
      local trunk_details trunk_id
      trunk_details=$(openstack port show "$port" -f value -c trunk_details 2>/dev/null)
      if [[ -n "$trunk_details" && "$trunk_details" != "None" ]]; then
        trunk_id=$(echo "$trunk_details" | python3 -c "
import sys, ast
d = ast.literal_eval(sys.stdin.read())
print(d.get('trunk_id', ''))
" 2>/dev/null)
        if [[ -n "$trunk_id" ]]; then
          echo "Deleting trunk $trunk_id (parent port $port in ${network_name})"
          openstack network trunk delete "$trunk_id" || true
        fi
      fi
    done

    local other_ports
    other_ports=$(openstack port list --network "$network_id" -f value -c ID -c device_owner \
                    | grep -vE "network:router_interface|network:dhcp" | awk '{ print $1 }')
    local other_port_count
    other_port_count=$(echo "$other_ports" | grep -c . || true)
    echo "Deleting ${other_port_count} port(s) in ${network_name}"
    for port in $other_ports; do
      remove_port "$port"
    done

    local subnets
    subnets=$(openstack subnet list --network "$network_id" -f value -c ID 2>/dev/null)
    for subnet in $subnets; do
      echo "Deleting subnet ${subnet} from network ${network_name}"
      openstack subnet delete "${subnet}" || \
        echo "WARN: could not delete subnet ${subnet}"
    done

    echo "Deleting network ${network_name} (${network_id})"
    openstack network delete "${network_id}" || \
      echo "WARN: could not delete network ${network_name} (${network_id})"
  done
}

function cleanup_security_groups() {
  for secgroup in $(openstack security group list -f value -c Name | grep tempest); do
    echo "Security group $secgroup will be deleted"
    openstack security group delete "${secgroup}"
  done
}

function cleanup_address_groups() {
  for ag in $(openstack address group list -c Name -f value | grep tempest-test);
  do
    echo "Address group $ag will be deleted"
    openstack address group delete $ag
  done
}

function is_tempest_resource_name() {
    local name="$1"
    [[ "$name" =~ ^neutron-tempest ]] && return 1
    [[ "$name" =~ locust ]]           && return 1
    [[ "$name" =~ tempest ]]          && return 0
    return 1
}

function is_tempest_network_name() {
    local name="$1"
    [[ "$name" =~ ^neutron-tempest ]] && return 1
    [[ "$name" =~ locust ]]           && return 1
    [[ "$name" =~ ^tempest- ]]        && return 0
    [[ "$name" == "tempest_test" ]]   && return 0
    return 1
}

function cleanup_fips() {
    local -A tempest_ports=()
    local port_id net_id net_name

    while read -r net_id net_name; do
        is_tempest_network_name "$net_name" || continue
        while read -r port_id; do
            [[ -n "$port_id" ]] && tempest_ports["$port_id"]=1
        done < <(openstack port list --network "$net_id" -f value -c ID)
    done < <(openstack network list -f value -c ID -c Name)

    if [[ ${#tempest_ports[@]} -eq 0 ]]; then
        echo "No tempest ports found, skipping FIP cleanup"
        return
    fi

    local fip_id
    while read -r fip_id port_id; do
        [[ -z "$port_id" || "$port_id" == "None" ]] && continue
        if [[ -n "${tempest_ports[$port_id]}" ]]; then
            echo "Deleting FIP $fip_id (port $port_id)"
            openstack floating ip delete "$fip_id" || true
        fi
    done < <(openstack floating ip list -f value -c ID -c "Port ID")
}

function cleanup_tempest_leftovers() {

  echo "Run cleanup"

  # Grep all ports and put in a list, only IPv4
  COUNTER=0
  for user in neutron-tempestuser1 neutron-tempestuser2 neutron-tempestuser3 neutron-tempestuser4 neutron-tempestuser5 neutron-tempestuser6 neutron-tempestuser7 neutron-tempestuser8 neutron-tempestuser9 neutron-tempestuser10; do
    let COUNTER++
    export OS_USERNAME=$user
    TEMPESTPROJECT=neutron-tempest$COUNTER
    export OS_TENANT_NAME=$TEMPESTPROJECT
    export OS_PROJECT_NAME=$TEMPESTPROJECT
    openstack port list -f value -c ID -c status -c "Fixed IPs" -c "device_owner" | grep "10\.199\.0\." | grep -E "ACTIVE|DOWN" | grep -v "network:router_interface" | awk '{ print $1 }' >> /tmp/myList.txt
  done

  # grep all ports from admin and put in a list, only IPv4
  COUNTER=0
  for user in neutron-tempestadmin1 neutron-tempestadmin2 neutron-tempestadmin3 neutron-tempestadmin4; do
    let COUNTER++
    export OS_USERNAME=$user
    TEMPESTPROJECT=neutron-tempest-admin$COUNTER
    export OS_TENANT_NAME=$TEMPESTPROJECT
    export OS_PROJECT_NAME=$TEMPESTPROJECT
    openstack port list -f value -c ID -c status -c "Fixed IPs" -c "device_owner" | grep "10\.199\.0\." | grep -E "ACTIVE|DOWN" | grep -v "network:router_interface" | awk '{ print $1 }' >> /tmp/myList.txt
  done

  # sort unique the list
  sort -u /tmp/myList.txt > /tmp/mySortedList.txt
  # disable and remove ip from the ports and delete all ports as admin
  while read port; do openstack port set ${port} --disable --no-fixed-ip && openstack port delete ${port}; done < /tmp/mySortedList.txt

  # Delete all networks and routers
  COUNTER=0
  for user in neutron-tempestuser1 neutron-tempestuser2 neutron-tempestuser3 neutron-tempestuser4 neutron-tempestuser5 neutron-tempestuser6 neutron-tempestuser7 neutron-tempestuser8 neutron-tempestuser9 neutron-tempestuser10; do
    let COUNTER++
    export OS_USERNAME=$user
    TEMPESTPROJECT=neutron-tempest$COUNTER
    export OS_TENANT_NAME=$TEMPESTPROJECT
    export OS_PROJECT_NAME=$TEMPESTPROJECT
    cleanup_fips
    cleanup_ports_and_networks "tempest-test-network"
    cleanup_ports_and_networks "tempest-\w*[A-Z]+\S+"
    for subnet in $(openstack subnet list | grep -E "tempest-lb_member" | awk '{ print $4 }'); do echo Subnet ${subnet} will be deleted; openstack subnet delete ${subnet}; done
    for pool in $(openstack subnet pool list | grep -E "tempest" | awk '{ print $2 }'); do openstack subnet pool delete ${pool}; done
    for router in $(openstack router list | grep -E "tempest" | awk '{ print $2 }'); do openstack router delete ${router}; done
    cleanup_ports_and_networks "tempest-test-network"
    cleanup_ports_and_networks "tempest-\w*[A-Z]+\S+"
    cleanup_security_groups
  done


  # Delete all networks, routers, subnets and subnet pools for Admin
  export OS_USERNAME='neutron-tempestadmin1'
  export OS_TENANT_NAME='neutron-tempest-admin1'
  export OS_PROJECT_NAME='neutron-tempest-admin1'
  cleanup_ports_and_networks "tempest-test-network"
  cleanup_ports_and_networks "tempest-\w*[A-Z]+\S+"
  cleanup_address_groups
  for subnet in $(openstack subnet list | grep -E "tempest-lb_member" | awk '{ print $4 }'); do echo Subnet ${subnet} will be deleted; openstack subnet delete ${subnet}; done
  for pool in $(openstack subnet pool list | grep -E "tempest" | awk '{ print $2 }'); do openstack subnet pool delete ${pool}; done
  for addscope in $(openstack address scope list | grep "tempest-\w*" |  awk '{ print $2 }'); do
    openstack address scope delete ${addscope}
  done
  for router in $(openstack router list | grep -E "tempest" | awk '{ print $2 }'); do openstack router delete ${router}; done
  cleanup_ports_and_networks "tempest-test-network"
  cleanup_ports_and_networks "tempest-\w*[A-Z]+\S+"
  cleanup_security_groups
}

{{- include "tempest-base.function_main" . }}

main
