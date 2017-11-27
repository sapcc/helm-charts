{{- if .Values.cinder.db_purge.enabled }}
#!/bin/bash

function start_application {

  set -e

  unset http_proxy https_proxy all_proxy no_proxy

  echo "INFO: copying cinder config files to /etc/cinder"
  cp -v /cinder-etc/* /etc/cinder
  
  # as we can't use cron here (not running as root) we run an endless loop to run the script periodically
  echo "INFO: starting a loop to periodically purge old deleted instance from the cinder db"
  while true; do
    . /cinder-db-purge-bin/cinder-db-purge
    sleep $(( 60 * {{ .Values.cinder.db_purge.interval }} ))
  done

}

start_application
{{- end }}
