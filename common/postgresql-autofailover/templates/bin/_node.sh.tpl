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

chmod g+s /run/postgresql
chown -R postgres /run/postgresql

: ${POSTGRES_USER:=postgres}
: ${POSTGRES_DB:=$POSTGRES_USER}
: ${PGPORT:=5432}
export POSTGRES_USER POSTGRES_DB PGPORT
POD_INDEX=${HOSTNAME##*-}

# Perform all actions as $POSTGRES_USER
psql=( psql -v ON_ERROR_STOP=1 )
psql+=( --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" )

if [ ! -s "$PGDATA/PG_VERSION" ]; then
  if [ ! -e $PGDATA ]; then
    mkdir $PGDATA
  fi
  chown -R postgres $PGDATA

  echo
  echo "Creating node ..."
  echo

  # node 0 is considered the primary
  PG_AUTOCTL_CANDIDATE_PRIORITY=$((100 - $POD_INDEX))
  MONITOR_FQDN=${MONITOR_FQDN:-{{ include "postgresql-auto-failover.monitor.fullname" . }}.{{ .Release.Namespace }}.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }}}
  gosu postgres pg_autoctl create postgres \
    --name ${HOSTNAME} \
    --hostname ${HOSTNAME}.archer-postgresql.{{ .Release.Namespace }}.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }} \
    --username ${POSTGRES_USER} \
    --candidate-priority $PG_AUTOCTL_CANDIDATE_PRIORITY \
    --dbname ${POSTGRES_DB} \
    --no-ssl \
    --ssl-mode disable \
    --monitor "postgres://autoctl_node@$MONITOR_FQDN:5432/pg_auto_failover" \
    --skip-pg-hba

  echo
  echo "Configuring node ..."
  echo
  cp /postgresql-conf/pg_hba.conf $PGDATA/pg_hba.conf

  echo
  echo "Temporary starting node ..."
  echo

  gosu postgres pg_ctl -D "$PGDATA" \
    -o "-c listen_addresses='localhost'" \
    -w start

  echo
  for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
      *.sh)     echo "$0: running $f"; . "$f" ;;
      *.sql)    echo "$0: running $f"; "${psql[@]}" < "$f"; echo ;;
      *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${psql[@]}"; echo ;;
      *)        echo "$0: ignoring $f" ;;
    esac
    echo
  done

  echo
  echo "Stopping temporary started monitor ..."
  echo
  gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop

  echo
  echo 'PostgreSQL init process complete; ready for start up.'
  echo
else
  # Perform any maintenance activity

  echo
  echo "Temporary starting node ..."
  echo
  gosu postgres pg_ctl -D "$PGDATA" \
      -o "-c listen_addresses='localhost'" \
      -w start

  echo
  for f in /docker-entrypoint-maintaindb.d/*; do
    case "$f" in
      *.sh)     echo "$0: running $f"; . "$f" ;;
      *.sql)    echo "$0: running $f"; "${psql[@]}" < "$f"; echo ;;
      *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${psql[@]}"; echo ;;
      *)        echo "$0: ignoring $f" ;;
    esac
    echo
  done

  echo
  echo "Stopping temporary started monitor ..."
  echo
  gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop
fi


echo
echo "Starting node ..."
echo
exec gosu postgres pg_autoctl run --pgport $PGPORT &
pid=$!

_term() {
  echo "$(date '+%H:%M:%S') $$  INFO Received termination signal"
  local_group_state=$(pg_autoctl show state --local --json | jq .current_group_state -r)
  if [ "$local_group_state" == "primary" ]; then
    echo "$(date '+%H:%M:%S') $$  INFO $HOSTNAME in primary state, failing over"
    exec pg_autoctl perform failover
  fi

  kill -SIGTERM $pid; wait $pid
}

trap _term TERM INT
wait $pid
