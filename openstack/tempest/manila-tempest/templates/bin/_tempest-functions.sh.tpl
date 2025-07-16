#!/usr/bin/env bash

function delete_share_network() {
    local share_network_id=$1
    if ! manila share-network-show "$share_network_id" &>/dev/null; then
        echo "Share network $share_network_id does not exist, skipping deletion."
        return
    fi
    # Delete share network subnets if they exist
    subnets=$(openstack share network show "$share_network_id" -f value -c share_network_subnets)
    subnet_ids=$(echo "$subnets" | grep -oE "'id': '[^']+" | awk -F"'" '{print $4}')
    if [ -n "$subnet_ids" ]; then
        for subnet_id in $subnet_ids; do
            if ! manila share-network-subnet-delete "$share_network_id" "$subnet_id"; then
                echo "Failed to delete share network subnet: $subnet_id"
                exit 1
            fi
        done
    fi
    manila share-network-delete "$share_network_id" || echo "Failed to delete share network: $share_network_id" 
}

function cleanup_project_resources() {
    local pre_created_share_networks=("$1" "$2" "$3")
    echo "Run cleanup project $OS_PROJECT_NAME"
    for snap in $(manila snapshot-list | grep -E 'tempest' | awk '{ print $2 }'); do manila snapshot-delete ${snap}; done
    for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila reset-state ${share} && manila delete ${share}; done
    for share in $(manila list | grep -E 'tempest|share' | awk '{ print $2 }'); do manila reset-task-state ${share} && manila delete ${share}; done
    for net in $(manila share-network-list | grep -E 'tempest|None' | awk '{ print $2 }')
    do
        # don't delete pre-created share networks
        if [[ ! " ${pre_created_share_networks[@]} " =~ " ${net} " ]]; then
            delete_share_network ${net}
        fi
    done
    for ss in $(manila security-service-list --detailed 1 --columns "id,name,user"| grep -E 'tempest|None' | awk '{ print $2 }'); do manila security-service-delete ${ss}; done
}

function cleanup_tempest_leftovers() {
    share_network_id={{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.share_network_id }}
    alt_share_network_id={{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.alt_share_network_id }}
    admin_share_network_id={{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_share_network_id }}
    pre_created_share_networks=("$share_network_id" "$alt_share_network_id" "$admin_share_network_id")

    for i in $(seq 1 2); do
        export OS_USERNAME=manila-tempestuser${i}
        export OS_TENANT_NAME=tempest${i}
        export OS_PROJECT_NAME=tempest${i}
        cleanup_project_resources "$share_network_id" "$alt_share_network_id" "$admin_share_network_id"
    done

    export OS_USERNAME='admin'
    export OS_TENANT_NAME='admin'
    export OS_PROJECT_NAME='admin'
    cleanup_project_resources "$share_network_id" "$alt_share_network_id" "$admin_share_network_id"

    # Additional admin-only cleanup
    for group_type in $(manila share-group-type-list | grep -E 'tempest' | awk '{ print $2 }'); do manila share-group-type-delete ${group_type}; done
    for type in $(manila type-list | grep -E 'tempest' | awk '{ print $2 }'); do manila type-delete ${type}; done
}

# vim: set ft=bash ts=4 sw=4 et:
