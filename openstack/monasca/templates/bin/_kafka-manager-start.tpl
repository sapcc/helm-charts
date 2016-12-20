{{- define "kafka_manager_start_tpl" -}}
#!/bin/bash

# set some env variables from the openstack env properly based on env
. /container.init/common-start


function process_config {
  # use defaults if no specific node configuration available
  cp -f /monasca-etc-common/kafka-manager-application.conf /opt/kafka-manager-$VERSION/conf/application.conf

}

function start_application {
  # make sure Zookeeper is around
  echo "Start kafka manager"
  cd /opt/kafka-manager-$VERSION/ && bin/kafka-manager
}

process_config

start_application

{{ end }}
