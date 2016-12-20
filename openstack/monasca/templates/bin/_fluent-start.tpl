{{- define "fluent_start_tpl" -}}
#!/bin/bash

. /container.init/common-start

function process_config {

  cp /monasca-etc-log/fluent-${NODE_TYPE}.conf /etc/fluent/fluent.conf
  if [ $NODE_TYPE == "fluent" ]; then
    echo $KUBERNETES_SERVICE_HOST
    sed -i "s|KUBERNETES_SERVICE_HOST|$KUBERNETES_SERVICE_HOST|g" /etc/fluent/fluent.conf
  fi
}

function start_application {

  #/usr/local/bin/fluentd --use-v1-config --suppress-repeated-stacktrace 
  exec /usr/local/bin/fluentd --use-v1-config

}

process_config

start_application
{{ end }}
