#!/bin/bash

function process_config {

  cp /grafana-etc/create-session-table.sql /docker-entrypoint-initdb.d/create-session-table.sql

}

function start_application {

  # this is to be safe, as we use persistent storage
  echo "starting postgres with lock /postgresql/postgres.lock"
  LOCKFILE=/postgresql/postgres.lock
  exec 9>${LOCKFILE}
  /usr/bin/flock -n 9
  /usr/local/bin/docker-entrypoint.sh postgres

}

process_config

start_application
