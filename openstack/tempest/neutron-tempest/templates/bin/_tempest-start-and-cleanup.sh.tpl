#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

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

function cleanup_ports_and_networks() {
    local net_id net_name port_id router_id trunk_id trunk_details

    while read -r net_id net_name; do
        is_tempest_network_name "$net_name" || continue
        echo "Processing network: $net_name ($net_id)"

        while read -r port_id router_id; do
            echo "Removing interface $port_id from router $router_id"
            openstack router remove port "$router_id" "$port_id" || true
        done < <(openstack port list --network "$net_id" \
                    --device-owner network:router_interface \
                    -f value -c ID -c device_id)

        mapfile -t port_ids < <(openstack port list --network "$net_id" -f value -c ID)

        for port_id in "${port_ids[@]}"; do
            trunk_details=$(openstack port show "$port_id" -f value -c trunk_details 2>/dev/null)
            if [[ -z "$trunk_details" || "$trunk_details" == "None" ]]; then
                continue
            fi
            trunk_id=$(echo "$trunk_details" | python3 -c "
import sys, ast
d = ast.literal_eval(sys.stdin.read())
print(d.get('trunk_id', ''))
" 2>/dev/null)
            if [[ -n "$trunk_id" ]]; then
                echo "Deleting trunk $trunk_id (parent port $port_id in tempest network $net_name)"
                openstack network trunk delete "$trunk_id" || true
            fi
        done

        if [[ ${#port_ids[@]} -gt 0 ]]; then
            echo "Deleting ${#port_ids[@]} ports in $net_name"
            openstack port delete "${port_ids[@]}" || true
        fi

        mapfile -t subnet_ids < <(openstack subnet list --network "$net_id" -f value -c ID)
        if [[ ${#subnet_ids[@]} -gt 0 ]]; then
            echo "Deleting subnets for $net_name"
            openstack subnet delete "${subnet_ids[@]}" || true
        fi

        echo "Deleting network $net_name"
        openstack network delete "$net_id" || true
    done < <(openstack network list -f value -c ID -c Name)
}

function cleanup_routers() {
    local router_id router_name port_id

    while read -r router_id router_name; do
        is_tempest_resource_name "$router_name" || continue
        echo "Cleaning up router $router_name"
        openstack router unset --external-gateway "$router_id" || true

        mapfile -t port_ids < <(openstack port list --router "$router_id" -f value -c ID)
        for port_id in "${port_ids[@]}"; do
            openstack router remove port "$router_id" "$port_id" || true
        done

        openstack router delete "$router_id" || true
    done < <(openstack router list -f value -c ID -c Name)
}

function cleanup_security_groups() {
    local sg_id sg_name

    while read -r sg_id sg_name; do
        [[ "$sg_name" == "default" ]] && continue
        is_tempest_resource_name "$sg_name" || continue
        echo "Deleting security group $sg_name"
        openstack security group delete "$sg_id" || true
    done < <(openstack security group list -f value -c ID -c Name)
}

function cleanup_project_neutron() {
    cleanup_fips
    cleanup_ports_and_networks
    cleanup_routers
    cleanup_security_groups

    local id name
    for res in "address group" "subnet pool" "address scope"; do
        while read -r id name; do
            is_tempest_resource_name "$name" || continue
            echo "Deleting $res $name"
            openstack $res delete "$id" || true
        done < <(openstack $res list -f value -c ID -c Name)
    done
}

function cleanup_tempest_leftovers() {
    echo "Starting Neutron-only cleanup"

    for i in $(seq 1 10); do
        export OS_USERNAME="neutron-tempestuser$i"
        export OS_PROJECT_NAME="neutron-tempest$i"
        export OS_TENANT_NAME="neutron-tempest$i"
        cleanup_project_neutron
    done

    for i in $(seq 1 4); do
        export OS_USERNAME="neutron-tempestadmin$i"
        export OS_PROJECT_NAME="neutron-tempest-admin$i"
        export OS_TENANT_NAME="neutron-tempest-admin$i"
        cleanup_project_neutron
    done
}

{{- include "tempest-base.function_main" . }}

main
