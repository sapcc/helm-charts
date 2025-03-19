#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /usr/bin/common-functions.sh

# Health check that exits with a non-zero code if target node does not have an active listener for given port
checkrabbitmq 'check_port_listener {{ $.Values.ports.public | int }}'
checkrabbitmq 'check_port_listener {{ $.Values.ports.management | int }}'
# Health check that exits with a non-zero code if target node does not have an active listener for given protocol
checkrabbitmq 'check_protocol_listener http'
checkrabbitmq 'check_protocol_listener clustering'
checkrabbitmq 'check_protocol_listener amqp'
# Health check that checks if all vhosts are running in the target node
checkrabbitmq check_virtual_hosts
# query RabbitMQ version
checkrabbitmq server_version
# validate admin user credentials
rabbitmqctl authenticate_user --quiet "$(cat /etc/rabbitmq/secrets/user_admin_username)" "$(cat /etc/rabbitmq/secrets/user_admin_password)"
