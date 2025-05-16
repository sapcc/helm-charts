#!/usr/bin/env bash

# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

for env in HOSTNAME BUILDING_BLOCK HOST_IP AVAILABILITY_ZONE; do
    if [ -z "${!env}" ]; then
        echo "$env is not set. Exiting..."
        exit 1
    fi
done

# Wait for ovsdb server
while true; do
    /usr/bin/ovs-vsctl show
    if [ $? -eq 0 ]; then
        break
    else
        echo "ovsdb-server seems not be ready yet. Waiting..."
        sleep 1
    fi
done

set -eEuxo pipefail

# Generate stable UUID from hostname
echo "Generating stable UUID from hostname "${HOSTNAME}" | md5sum..."
HASH=$(echo -n "${HOSTNAME}" | md5sum | cut -d' ' -f1)
ovs-vsctl set open . external-ids:system-id=${HASH:0:8}-${HASH:8:4}-${HASH:12:4}-${HASH:16:4}-${HASH:20:12}
ovs-vsctl set open . external-ids:hostname=${HOSTNAME}
ovs-vsctl set open . external-ids:ovn-encap-ip=${HOST_IP}

ovs-vsctl set open . external-ids:ovn-bridge-mappings=${BUILDING_BLOCK}:{{ default "br-ex" .Values.ovn.external_bridge }}
ovs-vsctl set open . external-ids:ovn-bridge={{ default "br-int" .Values.ovn.integration_bridge }}
ovs-vsctl set open . external-ids:ovn-cms-options="enable-chassis-as-gw,availability-zones=${AVAILABILITY_ZONE}"

# Set any additional external-ids
{{- range $k, $v := .Values.ovn.external_ids }}
ovs-vsctl set open . external-ids:{{ $k | kebabcase }}={{ $v }}
{{- end }}
