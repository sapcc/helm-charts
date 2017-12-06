{{- if .Values.nova.db_purge.enabled }}
#!/bin/bash

function start_application {

  set -e

# we no longer use the cron based approach
#  export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}
#  export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}

  unset http_proxy https_proxy all_proxy no_proxy

  echo "INFO: copying nova config files to /etc/nova"
  cp -v /nova-etc/* /etc/nova
  
# we no longer use the cron based approach
#  echo "INFO: setting up cron job to purge old deleted instance from the nova db"
#  cat <(crontab -l) <(echo "*/{{ .Values.nova.db_purge.interval }} * * * * . /nova-db-purge-bin/nova-db-purge > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -
#  crontab -l
#
#  echo "INFO: starting cron in foreground"
#  exec cron -f

  # we run an endless loop to run the script periodically
  echo "INFO: starting a loop to periodically purge old deleted instances from the nova db"
  while true; do
    . /nova-db-purge-bin/nova-db-purge
    sleep $(( 60 * {{ .Values.nova.db_purge.interval }} ))
  done

}

start_application
{{- end }}
