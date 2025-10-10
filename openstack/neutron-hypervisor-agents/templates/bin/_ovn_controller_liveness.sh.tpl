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

# Check if ovn-controller is running
check_ovn_controller_pid() {
    if ! pidof -q ovn-controller; then
        error_exit "ERROR - ovn-controller is not running"
    fi
}

# Function to check the running status of ovn-controller
check_ovn_controller_status() {
    # Capture output and check exit status
    if ! output=$(ovn-appctl -t ovn-controller debug/status 2>&1); then
        error_exit "ERROR - Failed to get status from ovn-controller, ovn-appctl exit status: $?"
    fi

    if [ "$output" != "running" ]; then
        error_exit "ERROR - ovn-controller status is '$output', expecting 'running' status"
    fi
}


check_ovn_controller_pid
check_ovn_controller_status
