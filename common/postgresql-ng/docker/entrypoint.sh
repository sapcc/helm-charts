#!/usr/bin/env bash

# heavily based and simplified on https://github.com/docker-library/postgres/blob/master/docker-entrypoint.sh which is licensed under MIT

set -eou pipefail
shopt -s nullglob # who thought it is a good idea to return the glob if it matches nothing?

[[ -n ${DEBUG:-} ]] && set -x

# those are set by default in values, too but are kept here to easen testing
export PGVERSION="${PGVERSION:-16}"
export PGUSER="${PGUSER:-postgres}"
# export PGPASSWORD=${PGPASSWORD:-secure} # this not to not create security incidents
# always generate a new password on each start
PGPASSWORD="$(head -c 30 </dev/urandom | base64)"
export PGPASSWORD
export PGDATABASE="${PGDATABASE:-acme-db}"

if [[ $(id -u) == 0 ]]; then
  for _ in /var/lib/postgresql/*; do
    echo "/var/lib/postgresql must be empty otherwise data is being deleted! Mount your PVC at /data"
    exit 1
  done

  # do a one time migration from old postgres chart
  if [[ -e /data/PG_VERSION ]]; then
    old_version=$(cat /data/PG_VERSION)

    # move to a temporary directory
    mkdir -p /data-old
    mv /data/* /data-old/

    # and move back to the right place
    mkdir "/data/postgresql/$old_version"
    mv /data-old/* "/data/postgresql/$old_version/"
    chown postgres:postgres -R /data/postgresql
  fi

  # setup the default directories with correct permissions
  # we cannot change the owner of the volume mount point or make /var/lib a volume
  if [[ ! -h /var/lib/postgresql || ! -e /data/postgresql ]]; then
    mkdir -p /data/postgresql
    rmdir /var/lib/postgresql
    ln -sr /data/postgresql /var/lib/
    chown postgres:postgres /var/lib/postgresql
  fi

  exec gosu postgres "$0"
fi

if [[ ! -e /usr/lib/postgresql/$PGVERSION ]]; then
  PGBIN=/usr/lib/postgresql/$PGVERSION
  echo "Postgresql $PGVERSION is not installed, aborting"
  exit 1
fi
export PGBIN="/usr/lib/postgresql/$PGVERSION/bin"
export PATH="$PGBIN:$PATH"
export PGDATA="/var/lib/postgresql/$PGVERSION" # hardcoded because we are being lazy

if [[ -z ${PGPASSWORD:-} ]]; then
  echo "PGPASSWORD env must be set!"
  exit 1
fi
if [[ ${#PGPASSWORD} -ge 100 ]]; then
  echo "PGPASSWORD env cannot be 100 chars long"
  exit 1
fi

process_sql() {
  local query_runner=(psql -v ON_ERROR_STOP=1 --username "$PGUSER" --no-password --no-psqlrc)
  if [[ -n $PGDATABASE ]]; then
    query_runner+=(--dbname "$PGDATABASE")
  fi

  PGHOST='' PGHOSTADDR='' "${query_runner[@]}" "$@"
}

created_db=false
updated_db=false

# create the database if the version file is missing. This is also required when running pg_upgrade.
if [[ ! -e $PGDATA/PG_VERSION ]]; then
  created_db=true
  initdb --username="$PGUSER" --pwfile=<(printf "%s\n" "$PGPASSWORD")
fi

# postgres 9.5,12 returns "on" instead of the the algorithm which is not a valid value for method
# see https://github.com/docker-library/postgres/commit/56eb8091dc67efe65b7a5a101e80ab83a9ca70a3#diff-9e7ea2740289a7dcbb948937cee573694c05642f9cd154c0a6f68547d8ac1ab4L215
auth="$(postgres -C password_encryption)"

if [[ $created_db == true ]]; then
  if [[ $auth == on ]]; then
    postgres_host_auth_method=md5
  else
    postgres_host_auth_method="$auth"
  fi
  echo -e "host  all  all  all  $postgres_host_auth_method\n" >>"$PGDATA/pg_hba.conf"
fi

# check for older postgres databases and upgrade from them if possible
found_current_db=false
for data in $(find /var/lib/postgresql/ -mindepth 1 -maxdepth 1 | sort --version-sort); do
  # we found a newer postgres version than the user wants to start
  if [[ $found_current_db == true ]]; then
    echo "Found a newer postgres database than being run. This is not supported and not a valid way to rollback"
    echo "Please restore a backup instead"
    exit 1
  fi

  if [[ $data == "$PGDATA" ]]; then
   found_current_db=true
   continue
  fi

  bindir="/usr/lib/postgresql/$(basename "$data")/bin"
  if [[ ! -d $bindir ]]; then
    echo "Old postgresql is not installed into $bindir, aborting upgrade"
    exit 1
  fi

  # pg_upgrade wants to have write permission for cwd
  cd /var/lib/postgresql
  pg_upgrade --link --jobs="$(nproc)" \
    --old-datadir "$data" --new-datadir "$PGDATA" \
    --old-bindir "$bindir" --new-bindir "$PGBIN"

  created_db=false # database already exists at this point
  updated_db=true
  ./delete_old_cluster.sh
  # postgres 12 generates an additional shellscript which only contains vacuumdb like we run it below
  rm -f delete_old_cluster.sh analyze_new_cluster.sh
  cd -
  break
done

pg_ctl -D "$PGDATA" -o "$(printf '%q ' -c listen_addresses='' -p 5432)" -w start

# run the recommended optimization by pg_upgrade to not mitigate performance decreases after an upgrade
if [[ $updated_db == true ]]; then
  vacuumdb --all --analyze-in-stages
fi

substituteSqlEnvs() {
  local file="$1" sedArgs=()

  for line in $(env | grep ^USER_PASSWORD_); do
    sedArgs+=(-e "s/%$(echo "$line" | cut -d= -f1)%/$(echo "$line" | cut -d= -f2)/g")
  done

  sed -e "s/%PGDATABASE%/$PGDATABASE/g" "${sedArgs[@]}" "$file"
}

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

# ensure that the configured password matches the password in the database
# this is required when upgrading the password hashing from md5 to scram-sha-256 which is the case when eg. updating from 9.5 to 15
# this also allows password rotations with restarts
PGDATABASE='' process_sql --dbname postgres --set user="$PGUSER" --set pw_method="$auth" --set password="$PGPASSWORD" <<-'EOSQL'
  SET password_encryption = :'pw_method';
  ALTER USER :user WITH PASSWORD :'password';
EOSQL

for file in /sql-on-startup.d/*.sql; do
  echo "Processing $file ..."
  process_sql -f <(substituteSqlEnvs "$file")
  echo
done
pg_ctl -D "$PGDATA" -m fast -w stop

# tell the startupProbe that we are done
touch /tmp/init-done

exec postgres "$@"
