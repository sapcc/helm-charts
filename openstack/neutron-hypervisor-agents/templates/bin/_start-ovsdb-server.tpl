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

set -eEuo pipefail

if pgrep -f /usr/sbin/ovsdb-server; then
    echo "Waiting to be the only highlander"
    exit 1
fi

mkdir -p /run/openvswitch
[ -f /var/lib/openvswitch/conf.db ] || ovsdb-tool create

exec /usr/sbin/ovsdb-server \
    --remote=punix:/run/openvswitch/db.sock --pidfile \
    -vconsole:emer -vsyslog:err -vfile:off
