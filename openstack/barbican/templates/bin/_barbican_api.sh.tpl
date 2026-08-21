#!/bin/bash

set -ex

COMMAND="${@:-start}"

function start () {
  for BARBICAN_WSGI_SCRIPT in barbican-wsgi-api; do
    cp -a $(type -p ${BARBICAN_WSGI_SCRIPT}) /var/www/cgi-bin/barbican/
  done

  if [ -f /etc/apache2/envvars ]; then
    source /etc/apache2/envvars
  fi

  if [ ! -d "$APACHE_RUN_DIR" ]; then
    mkdir -p "$APACHE_RUN_DIR"
  fi

  if [ -f "$APACHE_PID_FILE" ]; then
    rm -f "$APACHE_PID_FILE"
  fi

  exec apache2 -DFOREGROUND
}

function stop () {
  sleep {{ coalesce .Values.shutdownDelaySeconds .Values.global.shutdownDelaySeconds 10 }}
  apachectl -k graceful-stop
}

$COMMAND
