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

# Require HOSTNAME env to be set
if [ -z "${HOSTNAME}" ]; then
    echo "HOSTNAME env variable is not set. Exiting..."
    exit 1
fi

# Require BUILDING_BLOCK env to be set
if [ -z "${BUILDING_BLOCK}" ]; then
    echo "BUILDING_BLOCK env variable is not set. Exiting..."
    exit 1
fi

# Require HOST_IP env to be set
if [ -z "${HOST_IP}" ]; then
    echo "HOST_IP env variable is not set. Exiting..."
    exit 1
fi

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

ovs-vsctl set open . external-ids:system-id=${HOSTNAME}
ovs-vsctl set open . external-ids:hostname=${HOSTNAME}
ovs-vsctl set open . external-ids:ovn-encap-ip=${HOST_IP}
{{- with .Values.ovn.integration_bridge }}
ovs-vsctl set open . external-ids:ovn-bridge-mappings=${BUILDING_BLOCK}:{{ . }}
ovs-vsctl set open . external-ids:ovn-bridge={{ . }}
{{- end }}

# Set additional external-ids
{{- range $k, $v := .Values.ovn.external_ids }}
ovs-vsctl set open . external-ids:{{ $k | kebabcase }}={{ $v }}
{{- end }}

sleep inf