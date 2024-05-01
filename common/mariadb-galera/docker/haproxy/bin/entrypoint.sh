#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

MAX_RETRIES=10
WAIT_SECONDS=6

function checkconfig {
  loginfo "${FUNCNAME[0]}" "starting the HAProxy configuration check"
  /opt/haproxy/bin/haproxy -db -c -f /opt/haproxy/etc/haproxy.cfg
}

function starthaproxy {
  loginfo "${FUNCNAME[0]}" "starting HAproxy"
  exec /opt/haproxy/bin/haproxy -db -f /opt/haproxy/etc/haproxy.cfg
}

checkconfig
starthaproxy
