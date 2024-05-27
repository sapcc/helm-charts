#!/usr/bin/env bash

# heavily based and simplified on https://github.com/docker-library/postgres/blob/master/docker-entrypoint.sh which is licensed under MIT

set -eou pipefail
shopt -s nullglob        # who thought it is a good idea to return the glob if it matches nothing?
shopt -s inherit_errexit # fail if any subshell fails

# it is save to listen on 0.0.0.0 as the service is only exposed after the startupProbe passed
start_postgres() {
  pg_ctl -D "$PGDATA" -o "$(printf '%q ' -p 5432)" -w start
}

stop_postgres() {
  pg_ctl -D "$PGDATA" -m fast -w stop
}

process_sql() {
  local query_runner=(psql -v ON_ERROR_STOP=1 --username "$PGUSER" --no-password --no-psqlrc)
  if [[ -n $PGDATABASE ]]; then
    query_runner+=(--dbname "$PGDATABASE")
  fi

  PGHOST='' PGHOSTADDR='' "${query_runner[@]}" "$@"
}

substituteSqlEnvs() {
  local file="$1" sedArgs=()

  for line in $(env | grep ^USER_PASSWORD_); do
    sedArgs+=(-e "s|%$(echo "$line" | cut -d= -f1)%|$(echo "$line" | cut -d= -f2)|g")
  done

  sed -e "s/%PGDATABASE%/$PGDATABASE/g" "${sedArgs[@]}" "$file"
}

[[ ${DEBUG:-} != false ]] && set -x

if [[ ! -e /usr/lib/postgresql/$PGVERSION ]]; then
  echo "PostgreSQL $PGVERSION is not installed, aborting"
  exit 1
fi

# this script is run with USER root the first time; here we do some things that require root,
# afterwards we re-exec this script with USER postgres and run the rest
if [[ $(id -u) == 0 ]]; then
  # check that volume is mounted at the correct location
  for _ in /var/lib/postgresql/*; do
    echo "/var/lib/postgresql must be empty otherwise data is being deleted! Mount your PVC at /data"
    exit 1
  done

  # do a one time migration from old postgres chart
  if [[ -e /data/data/PG_VERSION ]]; then
    old_version=$(cat /data/data/PG_VERSION)

    # move to a temporary directory
    mkdir -p /data/old
    mv /data/data/* /data/old/
    rmdir /data/data

    # and move back to the right place
    # shellcheck disable=SC2174
    mkdir -m 700 -p "/data/postgresql/$old_version"
    mv /data/old/* "/data/postgresql/$old_version/"
    chown -R postgres:postgres /data/postgresql
    chmod -R 700 /data/postgresql

    touch /data/postgresql/$old_version/migrated_from_old_chart
  fi

  # setup the default directories with correct permissions
  # we cannot change the owner of the volume mount point or make /var/lib a volume
  if [[ ! -L /var/lib/postgresql || ! -e /data/postgresql ]]; then
    mkdir -p /data/postgresql
    rmdir /var/lib/postgresql
    ln -sr /data/postgresql /var/lib/
    chown postgres:postgres /var/lib/postgresql
  fi

  # pre-create the file to give the postgres user permission to write into it
  touch /postgres-password
  chown postgres:postgres /postgres-password

  exec gosu postgres "$0" "$@"
fi

export PATH="$PGBIN:$PATH"
created_db=false
updated_db=false

# always generate a new, random password on each start
PGPASSWORD="$(head -c 30 </dev/urandom | base64)"
echo -n "$PGPASSWORD" >/postgres-password
export PGPASSWORD

# create the database if the version file is missing. This is also required when running pg_upgrade.
if [[ ! -e $PGDATA/PG_VERSION ]]; then
  initdb --username="$PGUSER" --pwfile=<(printf "%s\n" "$PGPASSWORD")
  created_db=true
fi

# check for older postgres databases and upgrade from them if possible
found_current_db=false
# Only directories are matched to not match accidential left behind files or /var/lib/postgresql/update_extensions.sql.
# Also directories beginning with a dot like .cache or .local are ignored in case a login shell was ever used for the postgres user
for data in $(find /var/lib/postgresql/ -mindepth 1 -maxdepth 1 -type d -not -name ".*" | sort --version-sort); do
  # we found a newer postgres version than the user wants to start
  if [[ $found_current_db == true ]]; then
    echo "Found a newer postgres database than being run. This is not supported and not a valid way to rollback"
    echo "Please restore a backup instead"
    exit 1
  fi

  # if we found the current version last run and didn't encounter a newer one, we are good to go
  if [[ $data == "$PGDATA" ]]; then
    found_current_db=true
    continue
  fi

  # collect information about old postgres db, start it for a backup and then shutdown

  old_version=$(basename "$data")
  bindir="/usr/lib/postgresql/$old_version/bin"
  if [[ ! -d $bindir ]]; then
    echo "Old postgresql is not installed into $bindir, aborting upgrade"
    exit 1
  fi

  if (( $(echo "$old_version >= 12" | bc -l) )); then
    postgres_auth_method=scram-sha-256
  else
    postgres_auth_method=md5
  fi

  # create a backup unless we are migrating from the old chart
  if [[ ! -e /data/postgresql/$old_version/migrated_from_old_chart && ${PERSISTENCE_ENABLED:-false} == true ]]; then
    # set envs to start old postgres version
    old_path=$PATH
    old_pgbin=$PGBIN
    old_pgdata=$PGDATA
    export PGBIN="/usr/lib/postgresql/$old_version/bin"
    export PGDATA="/var/lib/postgresql/$old_version"
    export PATH="$PGBIN:$PATH"

    # only allow backup container to connect
    echo -e "local  all  postgres  trust\nhost  all  backup  all  $postgres_auth_method\nhost  all  postgres  all  $postgres_auth_method\n" >"$data/pg_hba.conf"
    touch /tmp/in-init # fake that we are online to expose the service

    # start postgres and load current hba conf
    start_postgres
    PGDATABASE='' process_sql --dbname postgres -c "SELECT pg_reload_conf()"

    # we need to retry loop here a bit because the k8s service, through which pgbackup must go, is probably not yet up
    for i in {1..60}; do
      # shellcheck disable=SC2154 # supplied by k8s
      curl --no-progress-meter --fail-with-body -X POST -u "backup:$USER_PASSWORD_backup" "http://$PGBACKUP_HOST:8080/v1/backup-now" && break
      sleep 1
    done
    if [[ $i == 60 ]]; then
      echo "Backup failed"
      exit 1
    fi

    # stop and restore originals envs
    stop_postgres
    PATH=$old_path
    PGBIN=$old_pgbin
    PGDATA=$old_pgdata
  fi

  # make sure the old pg_hba.conf contains valid entries for us
  echo -e "local  all  postgres  trust\nhost  all  backup  all  $postgres_auth_method\nhost  all  postgres  all  $postgres_auth_method\n" >"$data/pg_hba.conf"

  # pg_upgrade wants to have write permission for cwd
  cd /var/lib/postgresql
  pg_upgrade --link --jobs="$(nproc)" \
    --old-datadir "$data" --new-datadir "$PGDATA" \
    --old-bindir "$bindir" --new-bindir "$PGBIN"

  created_db=false # database already exists at this point
  updated_db=true
  ./delete_old_cluster.sh
  # postgres 12 generates an additional shellscript which only contains vacuumdb like we run it below
  # clear the old chart marker which might or might not exist and could be there from an upgrade that crashed previously
  rm -f delete_old_cluster.sh analyze_new_cluster.sh "/data/postgresql/$old_version/migrated_from_old_chart"
  cd -
  break
done

# restore standard pg_hba.conf and reload the config into postgres
cp /usr/local/share/pg_hba.conf "$PGDATA/pg_hba.conf"
echo -e "host  all  all  all  $PGAUTHMETHOD\n" >>"$PGDATA/pg_hba.conf"
# update postgres.conf
cp /etc/postgresql/postgresql.conf "$PGDATA/postgresql.conf"
start_postgres
PGDATABASE='' process_sql --dbname postgres -c "SELECT pg_reload_conf()"

# there might be some extensions which we need to enable
if [[ -f /var/lib/postgresql/update_extensions.sql ]]; then
  process_sql -f /var/lib/postgresql/update_extensions.sql
  rm /var/lib/postgresql/update_extensions.sql
fi

# run the recommended optimization by pg_upgrade to not mitigate performance decreases after an upgrade
if [[ $updated_db == true ]]; then
  vacuumdb --all --analyze-in-stages
fi

# if a new db was initted, create the databse inside of it and run init scripts
if [[ $created_db == true ]]; then
  # shellcheck disable=SC2097,SC2098 # false positive
  PGDATABASE='' process_sql --dbname postgres --set db="$PGDATABASE" <<-'EOSQL'
    CREATE DATABASE :"db";
	EOSQL

  for file in /sql-on-create.d/*.sql; do
    echo "Processing $file ..."
    process_sql -f <(substituteSqlEnvs "$file")
    echo
  done
fi

if (( $(echo "$PGVERSION >= 12" | bc -l) )); then
  postgres_auth_method=scram-sha-256
else
  postgres_auth_method=md5
fi

# ensure that the configured password matches the password in the database
# this is required when upgrading the password hashing from md5 to scram-sha-256 which is the case when eg. updating from 9.5 to 15
# this also allows password rotations with restarts
PGDATABASE='' process_sql --dbname postgres --set user="$PGUSER" --set password_encryption="$postgres_auth_method" --set password="$PGPASSWORD" <<-'EOSQL'
  SET password_encryption = :'password_encryption';
  ALTER USER :user WITH PASSWORD :'password';
EOSQL

for file in /sql-on-startup.d/*.sql; do
  echo "Processing $file ..."
  process_sql -f <(substituteSqlEnvs "$file")
  echo
done

# stop and exec later to properly attach to forward signals and stdout/stderr properly
stop_postgres
rm -f /tmp/in-init
touch /tmp/init-done

exec postgres "$@"
