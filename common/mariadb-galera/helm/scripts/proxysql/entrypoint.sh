#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function startproxy {
  loginfo "${FUNCNAME[0]}" "starting proxysql process"
  exec proxysql --config ${BASE}/etc/proxysql.cfg --exit-on-error --idle-threads --reload --no-version-check --foreground
}

startproxy
