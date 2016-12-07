#!/usr/bin/env bash

# set some env variables from the openstack env properly based on env
. /container.init/common-start

function process_config {

  echo "nothing to be done for process_config"

}

function start_application {

  # this is required to not get a new nodename with each new containername
  export RABBITMQ_NODENAME=ceilometer-rabbitmq@ceilometer-rabbitmq
  echo "make ceilometer-rabbitmq resolve to its name even if the service is not yet connected"
  echo "$CEILOMETER_RABBITMQ_IP ceilometer-rabbitmq" >> /etc/hosts

  # this seems to be required when having /var/lib/rabbitmq on persistent storage
  chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

  # this is to allow guest access from non localhost
  echo '[{rabbit, [{loopback_users, []}]}].' > /etc/rabbitmq/rabbitmq.config

  /etc/init.d/rabbitmq-server start

  rabbitmq-plugins enable rabbitmq_tracing || true
  rabbitmqctl trace_on || true

  # enable web console for debugging for now - should go when we go productive
  rabbitmq-plugins enable rabbitmq_management
  rabbitmqctl add_user {{.Values.ceilometer_rabbitmq_default_user}} {{.Values.ceilometer_rabbitmq_default_pass}} || true
  rabbitmqctl set_permissions {{.Values.ceilometer_rabbitmq_default_user}} ".*" ".*" ".*" || true

  rabbitmqctl change_password guest {{.Values.ceilometer_rabbitmq_default_pass}} || true
  /etc/init.d/rabbitmq-server stop

  echo "Starting Ceilometer RabbitMQ with lock /var/lib/rabbitmq/rabbitmq-server.lock"
  LOCKFILE=/var/lib/rabbitmq/rabbitmq-server.lock
  exec 9>${LOCKFILE}
  /usr/bin/flock -n 9
  exec gosu rabbitmq rabbitmq-server

}

process_config

start_application
