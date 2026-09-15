#!/bin/bash
#
# Copyright (c) 2018 SAP SE
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
echo "INFO: starting a loop to periodically run the nanny job for the glance db consistency check and purge"
while true; do

    # there is no consistency check for glance yet

    if [ "$GLANCE_DB_PURGE_ENABLED" = "True" ] || [ "$GLANCE_DB_PURGE_ENABLED" = "true" ]; then
        echo -n "INFO: purging at max $GLANCE_DB_PURGE_MAX_NUMBER deleted glance entities older than $GLANCE_DB_PURGE_OLDER_THAN days from the glance db - "
        date
        /var/lib/openstack/bin/glance-manage db purge --age_in_days $GLANCE_DB_PURGE_OLDER_THAN --max_rows $GLANCE_DB_PURGE_MAX_NUMBER
    fi
    echo -n "INFO: waiting $GLANCE_NANNY_INTERVAL minutes before starting the next loop run - "
    date
    sleep $(( 60 * $GLANCE_NANNY_INTERVAL ))
done
