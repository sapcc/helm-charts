#!/usr/bin/env bash

# do some tasks required for all ceilometer containers
. /ceilometer-bin/common-start

function process_config {
  cp /ceilometer-etc/api-paste.ini /etc/ceilometer/api_paste.ini
  cp /ceilometer-etc/ceilometer.conf /etc/ceilometer
  cp /ceilometer-etc/event-definitions.yaml /etc/ceilometer/event_definitions.yaml
  cp /ceilometer-etc/event-pipeline.yaml /etc/ceilometer/event_pipeline.yaml
  cp /ceilometer-etc/pipeline.yaml /etc/ceilometer
  cp /ceilometer-etc/policy.json /etc/ceilometer
}

function start_application {
    ceilometer-collector --config-dir /etc/ceilometer --config-file /etc/ceilometer/ceilometer.conf
}

process_config

start_application
