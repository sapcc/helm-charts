#!/usr/bin/env bash

set -ex

export STDOUT=${STDOUT:-/proc/1/fd/1}
export STDERR=${STDERR:-/proc/1/fd/2}

date

# repair any role-assignments that point to orphaned objects (usually users that have been deactivated in CAM)
keystone-manage-extension --config-file=/etc/keystone/keystone.conf repair_assignments {{ if .Values.skipRepairRoleAssignments }} --dry-run {{ end }} > ${STDOUT} 2> ${STDERR}
