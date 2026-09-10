#!/bin/bash
#
# Copyright (c) 2026 SAP SE
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

EXTRA_FLAGS=""
if [ "$BARBICAN_DB_CLEANUP_CLEAN_UNASSOCIATED_PROJECTS" = "True" ] || [ "$BARBICAN_DB_CLEANUP_CLEAN_UNASSOCIATED_PROJECTS" = "true" ]; then
    EXTRA_FLAGS="$EXTRA_FLAGS --clean-unassociated-projects"
fi
if [ "$BARBICAN_DB_CLEANUP_SOFT_DELETE_EXPIRED_SECRETS" = "True" ] || [ "$BARBICAN_DB_CLEANUP_SOFT_DELETE_EXPIRED_SECRETS" = "true" ]; then
    EXTRA_FLAGS="$EXTRA_FLAGS --soft-delete-expired-secrets"
fi

echo "INFO: starting a loop to periodically run the barbican db cleanup"
while true; do

    if [ "$BARBICAN_DB_CLEANUP_ENABLED" = "True" ] || [ "$BARBICAN_DB_CLEANUP_ENABLED" = "true" ]; then
        date
        /var/lib/openstack/bin/barbican-manage db clean \
            --min-days "$BARBICAN_DB_CLEANUP_MIN_NUM_DAYS" \
            --batch-size "$BARBICAN_DB_CLEANUP_BATCH_SIZE" \
            --verbose \
            $EXTRA_FLAGS
    fi
    echo -n "INFO: waiting $BARBICAN_DB_CLEANUP_INTERVAL minutes before starting the next loop run - "
    date
    sleep $(( 60 * $BARBICAN_DB_CLEANUP_INTERVAL ))
done
