#!/usr/bin/env bash

export STDOUT=${STDOUT:-/proc/1/fd/1}
export STDERR=${STDERR:-/proc/1/fd/2}

# repair any role-assignments that point to orphaned objects (usually from users that have been deactivated by CAM)
keystone-manage-extension --config-file=/etc/keystone/keystone.conf repair_assignments {{ if .Values.skipRepairRoleAssignments }} --dry-run {{ end }} > ${STDOUT} 2> ${STDERR}
