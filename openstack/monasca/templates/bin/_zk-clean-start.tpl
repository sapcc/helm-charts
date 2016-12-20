{{- define "zk_clean_start_tpl" -}}
#!/bin/bash

# set some env variables from the openstack env properly based on env
. /container.init/common-start

function process_config {

  echo "nothing to be done for process_config"

}

function start_application {

  set -e

  export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}  
  export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}
  
  cat <(crontab -l) <(echo "0 6 * * * java -cp /opt/zookeeper/zookeeper-3.4.9.jar:/opt/zookeeper/lib/slf4j-log4j12-1.6.1.jar:/opt/zookeeper/lib/slf4j-api-1.6.1.jar:/opt/zookeeper/lib/log4j-1.2.16.jar:/opt/zookeeper/conf org.apache.zookeeper.server.PurgeTxnLog /var/lib/zookeeper/datalogs /var/lib/zookeeper/data -n 3 > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -

  exec cron -f 

}

process_config

start_application
{{ end }}
