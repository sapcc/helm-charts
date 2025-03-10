#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /usr/bin/common-functions.sh

# Checks that the node OS process is up, registered with EPMD and CLI tools can authenticate with it
checkrabbitmq ping
# fully booted and running
checkrabbitmq check_running
# Basic TCP connectivity health check for each listener's port on the target node
checkrabbitmq check_port_connectivity
