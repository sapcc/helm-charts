#!/bin/bash

# Barbican API startup script
# Based on Keystone's keystone-api.sh pattern
# WP-1187: Migrate to Apache+mod_wsgi

set -ex

COMMAND="${@:-start}"

function start () {
  # Copy the WSGI script to the Apache CGI directory
  for BARBICAN_WSGI_SCRIPT in barbican-wsgi-api; do
    if type -p ${BARBICAN_WSGI_SCRIPT} > /dev/null 2>&1; then
      cp -a $(type -p ${BARBICAN_WSGI_SCRIPT}) /var/www/cgi-bin/barbican/
    elif [ -f /var/lib/openstack/bin/${BARBICAN_WSGI_SCRIPT} ]; then
      cp -a /var/lib/openstack/bin/${BARBICAN_WSGI_SCRIPT} /var/www/cgi-bin/barbican/
    else
      echo "ERROR: Cannot find ${BARBICAN_WSGI_SCRIPT}"
      exit 1
    fi
  done

  # Disable Apache status module (not needed, reduces attack surface)
  a2dismod status 2>/dev/null || true

  # Enable required Apache modules
  a2enmod wsgi 2>/dev/null || true
  {{- if .Values.tls.enabled }}
  a2enmod ssl 2>/dev/null || true
  {{- end }}

  # Load Apache2 environment variables
  if [ -f /etc/apache2/envvars ]; then
    source /etc/apache2/envvars
  fi

  # Set default Apache environment variables if not set
  # (required for images that don't have /etc/apache2/envvars)
  export APACHE_RUN_DIR=${APACHE_RUN_DIR:-/var/run/apache2}
  export APACHE_PID_FILE=${APACHE_PID_FILE:-${APACHE_RUN_DIR}/apache2.pid}
  export APACHE_RUN_USER=${APACHE_RUN_USER:-www-data}
  export APACHE_RUN_GROUP=${APACHE_RUN_GROUP:-www-data}
  export APACHE_LOG_DIR=${APACHE_LOG_DIR:-/var/log/apache2}

  # Create Apache runtime directory if it doesn't exist
  if [ ! -d "$APACHE_RUN_DIR" ]; then
    mkdir -p "$APACHE_RUN_DIR"
  fi

  # Remove stale PID file (for debian/ubuntu images)
  if [ -f "$APACHE_PID_FILE" ]; then
    rm -f "$APACHE_PID_FILE"
  fi

  # Start Apache2 in foreground
  exec apache2 -DFOREGROUND
}

function stop () {
  # Graceful shutdown with configurable delay
  sleep {{ coalesce .Values.shutdownDelaySeconds .Values.global.shutdownDelaySeconds 10 }}
  apachectl -k graceful-stop
}

$COMMAND