#!/bin/bash
#
# Copyright (c) 2024 SAP SE
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#

set -e

unset http_proxy https_proxy all_proxy no_proxy

# we run an endless loop to run the script periodically
echo "INFO: starting a loop to periodically run the nanny job for the BARBICAN secret movement"
while true; do

    # there is no consistency check for BARBICAN yet

    if [ "$BARBICAN_DB_SECRET_MOVE_ENABLED" = "True" ] || [ "$BARBICAN_DB_SECRET_MOVE_ENABLED" = "true" ]; then
        date
        /var/lib/openstack/bin/barbican-manage sap move_secrets --old-project-id $BARBICAN_DB_OLD_PROJECT_ID --new-project-id $BARBICAN_DB_NEW_PROJECT_ID
    fi
    echo -n "INFO: waiting $BARBICAN_NANNY_INTERVAL minutes before starting the next loop run - "
    date
    sleep $(( 60 * $BARBICAN_NANNY_INTERVAL ))
done
