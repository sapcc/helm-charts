#!/usr/bin/env bash
#
# Copyright 2022 Red Hat Inc.
#
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
set -ex
source $(dirname $0)/functions

DB_NAME="OVN_Northbound"
if [[ "${DB_TYPE}" == "sb" ]]; then
    DB_NAME="OVN_Southbound"
fi

# There is nothing special about -0 pod, except that it's always guaranteed to
# exist, assuming any replicas are ordered.
if [[ "$(hostname)" != "{{ .SERVICE_NAME }}-0" ]]; then
    ovs-appctl -t /tmp/ovn${DB_TYPE}_db.ctl cluster/leave ${DB_NAME}

    # wait for when the leader confirms we left the cluster
    while true; do
        # TODO: is there a better way to detect the cluster left state?..
        STATUS=$(ovs-appctl -t /tmp/ovn${DB_TYPE}_db.ctl cluster/status ${DB_NAME} | grep Status: | awk -e '{print $2}')
        if [ -z "$STATUS" -o "x$STATUS" = "xleft cluster" ]; then
            break
        fi
        sleep 1
    done
fi

# If replicas are 0 and *all* pods are removed, we still want to retain the
# database with its cid/sid for when the cluster is scaled back to > 0, so
# leaving the database file intact for -0 pod.
if [[ "$(hostname)" != "{{ .SERVICE_NAME }}-0" ]]; then
    # now that we left, the database file is no longer valid
    cleanup_db_file
fi

# Stop the DB server gracefully; this will also end the pod running script.
# By executing the stop command in the background, we guarantee to exit
# this script and not fail with "FailedPreStopHook", while the database is
# stopped.
/usr/share/ovn/scripts/ovn-ctl stop_${DB_TYPE}_ovsdb &
