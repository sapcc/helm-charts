#!/usr/bin/env bash
#
# Copyright 2023 SAP SE
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -euo pipefail

echo
echo "Fixing permissions ..."
echo
chmod -R 700 "/postgresql"
chown -R postgres "/postgresql"

# Check if monitor DB was initilized
if [ ! -d $PGDATA/pg_autoctl ]; then
  if [ ! -e $PGDATA ]; then
    mkdir $PGDATA
  fi
  chown -R postgres $PGDATA

  echo
  echo "Creating monitor ..."
  echo
  gosu postgres pg_autoctl create monitor \
    --no-ssl \
    --ssl-mode disable \
    --skip-pg-hba

  echo
  echo "Configuring monitor ..."
  echo
  cp /postgresql-conf/pg_hba.conf $PGDATA/pg_hba.conf
fi

echo
echo "Starting monitor ..."
echo
exec gosu postgres pg_autoctl run