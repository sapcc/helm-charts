#!/usr/bin/env bash

. /container.init/common.sh

function prepare_ovs {
    ovs_version=$(ovs-vsctl -V | grep ovs-vsctl | awk '{print $4}')
    ovs_db_version=$(ovsdb-tool schema-version /usr/share/openvswitch/vswitch.ovsschema)

    # begin configuring

    ovs-vsctl --no-wait -- init
    ovs-vsctl --no-wait -- set Open_vSwitch . db-version="${ovs_db_version}"
    ovs-vsctl --no-wait -- set Open_vSwitch . ovs-version="${ovs_version}"
    ovs-vsctl --no-wait -- set Open_vSwitch . system-type="docker-ovs"
    ovs-vsctl --no-wait -- set Open_vSwitch . system-version="0.1"
    ovs-vsctl --no-wait -- set Open_vSwitch . external-ids:system-id=`cat /proc/sys/kernel/random/uuid`
    ovs-vsctl --no-wait -- set-manager ptcp:6640
    ovs-appctl -t ovsdb-server ovsdb-server/add-remote db:Open_vSwitch,Open_vSwitch,manager_options
}


function configure_bridge {
    interfaces=( {{.Values.cp_network_interface}} )

    for interface in "${interfaces[@]}"
    do
        # Create the bridge and port on OVS, delete first and create ports for non internal bridges

        ovs-vsctl br-exists br-${interface}; rc=$?
        if [[ $rc == 0 ]]; then
            ovs-vsctl --no-wait del-br br-${interface}
        fi

        ovs-vsctl --no-wait add-br br-${interface}; rc=$?
        if [[ $rc != 0 ]]; then
          echo "Failed to create OVS bridge br-${interface} - exiting"
          exit $rc
        fi

        if [[ ! $interface == 'int' ]]
        then
            if [[ ! $(ovs-vsctl list-ports br-${interface}) =~ $(echo "\<${interface}\>") ]]; then
                ovs-vsctl --no-wait add-port br-${interface} ${interface}; rc=$?

                if [[ $rc != 0 ]]; then
                  echo "Failed to create OVS port ${interface} on bridge br-${interface} - exiting"
                  exit $rc
                fi
            fi
        fi

        ovs-vsctl br-exists br-${interface}; rc=$?
        if [[ $rc != 0 ]]; then
            echo "Failed to create bridge configuration"
            exit 1
        fi

    done
}

function _start_application {
    until ! pgrep -f /usr/sbin/ovs-vswitchd; do
      echo "Waiting to be the only highlander"
      sleep 5
    done
    touch /var/lib/neutron/neutron-ovs-ready

    prepare_ovs
    configure_bridge

    if command -v dumb-init >/dev/null 2>&1; then
        exec  dumb-init /usr/sbin/ovs-vswitchd unix:/var/run/openvswitch/db.sock -vconsole:warn -vsyslog:info -vfile:info --mlockall --pidfile
    else
        exec  /usr/sbin/ovs-vswitchd unix:/var/run/openvswitch/db.sock -vconsole:warn -vsyslog:info -vfile:info --mlockall --pidfile
    fi
}


start_application
