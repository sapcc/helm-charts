#!/usr/bin/env bash
set -eEuxo pipefail

PUBLIC_INTERFACE=bond0
OVS_PHYSICAL_BRIDGE=br-ovs0

if pgrep -f /usr/sbin/ovs-vswitchd; then
    echo "Waiting to be the only highlander"
    exit 1
fi

ovs_version=$(ovs-vsctl -V | grep ovs-vsctl | awk '{print $4}')
ovs_db_version=$(ovsdb-tool schema-version /usr/share/openvswitch/vswitch.ovsschema)

# begin configuring

ovs-vsctl --no-wait -- init
ovs-vsctl --no-wait -- set Open_vSwitch . db-version="${ovs_db_version}"
ovs-vsctl --no-wait -- set Open_vSwitch . ovs-version="${ovs_version}"
ovs-vsctl --no-wait -- set Open_vSwitch . system-type="docker-ovs"
ovs-vsctl --no-wait -- set Open_vSwitch . system-version="0.1"
ovs-vsctl --no-wait -- set Open_vSwitch . external-ids:system-id=`cat /proc/sys/kernel/random/uuid`
ovs-vsctl --no-wait -- set-manager punix:/var/run/openvswitch/db.sock
ovs-appctl -t ovsdb-server ovsdb-server/add-remote db:Open_vSwitch,Open_vSwitch,manager_options

ovs-vsctl --no-wait -- --may-exist add-br $OVS_PHYSICAL_BRIDGE
ovs-vsctl --no-wait -- --may-exist add-port $OVS_PHYSICAL_BRIDGE $PUBLIC_INTERFACE

export XDG_RUNTIME_DIR=/run/openvswitch

/usr/sbin/ovs-vswitchd unix:/run/openvswitch/db.sock \
    --mlockall --pidfile \
    -vconsole:warn -vsyslog:info -vfile:off &

PID=$!
trap "kill -TERM $PID" SIGTERM

while ! ip l show $OVS_PHYSICAL_BRIDGE; do
    sleep 1
done

ip link set $OVS_PHYSICAL_BRIDGE up
ip link set $PUBLIC_INTERFACE up

for IP in $(ip addr show dev $PUBLIC_INTERFACE | grep ' inet ' | awk '{print $2}'); do
    ip addr del $IP dev $PUBLIC_INTERFACE
    ip addr add $IP dev $OVS_PHYSICAL_BRIDGE
done

wait $PID
