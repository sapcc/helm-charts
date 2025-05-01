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

set -e

error_exit() {
    echo "$1" >&2
    exit 1
}

# Check if ovn-controller is connected to the OVN SB database
check_ovn_controller_connection() {
    if ! output=$(ovn-appctl -t ovn-controller connection-status 2>&1); then
        error_exit "ERROR - Failed to get connection status from ovn-controller, ovn-appctl exit status: $?"
    fi

    if [ "$output" != "connected" ]; then
        error_exit "ERROR - ovn-controller connection status is '$output', expecting 'connected' status"
    fi
}


check_ovn_controller_connection
