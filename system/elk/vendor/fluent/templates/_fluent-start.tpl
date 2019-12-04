#!/bin/bash

function process_config {
  cp /fluent-bin/fluent.conf /etc/fluent/fluent.conf
  cp /etc/ca.pem /usr/share/ca-certificates/ca.crt
  update-ca-certificates
  echo $KUBERNETES_SERVICE_HOST
  sed -i "s|KUBERNETES_SERVICE_HOST|$KUBERNETES_SERVICE_HOST|g" /etc/fluent/fluent.conf
}

function start_application {

  #/usr/local/bin/fluentd --use-v1-config --suppress-repeated-stacktrace 
  exec /usr/local/bin/fluentd --use-v1-config

}

process_config

start_application
