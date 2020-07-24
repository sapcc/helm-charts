#!/bin/bash
set -e

{{- if eq .Values.service.primary true }}

# A Primary/Bootstraping Node:
# The readiness check should always work:
mysql -h 127.0.0.1 -e "SELECT 1" || exit 1

{{- else }}

# Not a Primary Node...
# The readiness check should exit 0 when SST is in progress or just starting.
# That is becuase nodes are running on separate k8s clusters without a common service!
# (otherwise SST won't work).

if [[ -f /var/lib/mysql//.sst ]] ; then
    echo 'SST is in progress. File "/var/lib/mysql//.sst" exists.'
    exit 0
fi

if [[ ! -f /var/lib/mysql//grastate.dat ]] ; then
    echo 'File "/var/lib/mysql//grastate.dat" does not exist, node has just started.'
    exit 0
fi

# if no SST is running and the node has not just started, do a regular check:
mysql -h 127.0.0.1 -e "SELECT 1" || exit 1

{{- end }}
