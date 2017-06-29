#!/bin/bash

function process_config {
  unset http_proxy https_proxy all_proxy no_proxy
  cp /fluent-etc/fluent.conf /etc/fluent/fluent.conf
  echo $KUBERNETES_SERVICE_HOST
  sed -i "s|KUBERNETES_SERVICE_HOST|$KUBERNETES_SERVICE_HOST|g" /etc/fluent/fluent.conf
}

function start_application {

  #/usr/local/bin/fluentd --use-v1-config --suppress-repeated-stacktrace 
  export no_proxy=$no_proxy,100.
  exec /usr/local/bin/fluentd --use-v1-config

}

process_config

start_application
