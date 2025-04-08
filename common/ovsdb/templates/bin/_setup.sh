#!/usr/bin/env bash
#
# Copyright 2022 Red Hat Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# based on https://github.com/openstack-k8s-operators/ovn-operator/tree/main/templates/ovndbcluster/bin

set -ex
source $(dirname $0)/functions

DB_PORT="{{ .DB_PORT }}"
{{- if .TLS }}
DB_SCHEME="pssl"
{{- else }}
DB_SCHEME="ptcp"
{{- end }}
RAFT_PORT="{{ .RAFT_PORT }}"
NAMESPACE="{{ .NAMESPACE }}"
OPTS=""
DB_NAME="OVN_Northbound"
if [[ "${DB_TYPE}" == "sb" ]]; then
    DB_NAME="OVN_Southbound"
fi

PODNAME=$(hostname -f | cut -d. -f1,2)
PODIPV6=$(grep "${PODNAME}" /etc/hosts | grep ':' | cut -d$'\t' -f1)

if [[ "" = "${PODIPV6}" ]]; then
    DB_ADDR="0.0.0.0"
else
    DB_ADDR="[::]"
fi

# The --cluster-remote-addr / --cluster-local-addr options will have effect
# only on bootstrap, when we assume the leadership role for the first pod.
# Later, cli arguments are still passed, but raft membership hints are already
# stored in the databases, and hence the arguments are of no effect.
if [[ "$(hostname)" != "{{ .SERVICE_NAME }}-0" ]]; then
    #ovsdb-tool join-cluster /etc/ovn/ovn${DB_TYPE}_db.db ${DB_NAME} tcp:$(hostname).{{ .SERVICE_NAME }}.${NAMESPACE}.svc.cloud.local:${RAFT_PORT} tcp:{{ .SERVICE_NAME }}-0.{{ .SERVICE_NAME }}.${NAMESPACE}.svc.cluster.local:${RAFT_PORT}
    OPTS="--db-${DB_TYPE}-cluster-remote-addr={{ .SERVICE_NAME }}-0.{{ .SERVICE_NAME }}.{{ .NAMESPACE }}.svc.kubernetes.{{ .global.region }}.cloud.sap --db-${DB_TYPE}-cluster-remote-port=${RAFT_PORT}"
fi


# call to ovn-ctl directly instead of start-${DB_TYPE}-db-server to pass
# extra_args after --
set /usr/share/ovn/scripts/ovn-ctl --no-monitor

set "$@" --db-${DB_TYPE}-election-timer={{ .OVN_ELECTION_TIMER }}
set "$@" --db-${DB_TYPE}-cluster-local-addr=$(hostname -f)
set "$@" --db-${DB_TYPE}-cluster-local-port=${RAFT_PORT}
set "$@" --db-${DB_TYPE}-probe-interval-to-active={{ .OVN_PROBE_INTERVAL_TO_ACTIVE }}
set "$@" --db-${DB_TYPE}-addr=${DB_ADDR}
set "$@" --db-${DB_TYPE}-port=${DB_PORT}
{{- if .TLS }}
set "$@" --ovn-${DB_TYPE}-db-ssl-key={{.OVNDB_KEY_PATH}}
set "$@" --ovn-${DB_TYPE}-db-ssl-cert={{.OVNDB_CERT_PATH}}
set "$@" --ovn-${DB_TYPE}-db-ssl-ca-cert={{.OVNDB_CACERT_PATH}}
set "$@" --db-${DB_TYPE}-cluster-local-proto=ssl
set "$@" --db-${DB_TYPE}-cluster-remote-proto=ssl
set "$@" --db-${DB_TYPE}-create-insecure-remote=no
{{- else }}
set "$@" --db-${DB_TYPE}-cluster-local-proto=tcp
set "$@" --db-${DB_TYPE}-cluster-remote-proto=tcp
{{- end }}

# log to console
set "$@" --ovn-${DB_TYPE}-log=-vconsole:{{ .OVN_LOG_LEVEL }}

# if server attempts to log to file, ignore
#
# note: even with -vfile:off (see below), the server sometimes attempts to
# create a log file -> this argument makes sure it doesn't polute OVN_LOGDIR
# with a nearly empty log file
set "$@" --ovn-${DB_TYPE}-logfile=/dev/null

# If db file is empty, remove it; otherwise service won't start.
# See https://issues.redhat.com/browse/FDP-689 for more details.
if ! [ -s $DB_FILE ]; then
    cleanup_db_file
fi

# Must remove a cluster member to change protocol, replicas 1/2 will have
# left the cluster when terminating the pod, but cannot remove final member from
# a cluster (replica 0).
# Convert db to standalone mode on this member instead.
# Cluster then gets recreated by ovnctl run_*b_ovsdb using the new local address.
if [ "$(hostname)" == "{{ .SERVICE_NAME }}-0" ]; then
    DB_LOCAL_ADDR={{ if .TLS }}ssl{{ else }}tcp{{ end }}:$(hostname):${RAFT_PORT}
    if [ -e ${DB_FILE} ] && \
       ovsdb-tool db-is-clustered ${DB_FILE} && \
       ACTUAL_DB_LOCAL_ADDR="$(ovsdb-tool db-local-address ${DB_FILE})" && \
       [ "${ACTUAL_DB_LOCAL_ADDR}" != "${DB_LOCAL_ADDR}" ] \
       ; \
    then
        rm -f "${DB_FILE%.db}_standalone.db"
        if ovsdb-tool cluster-to-standalone "${DB_FILE%.db}_standalone.db" "${DB_FILE}"; then
            mv -f "${DB_FILE%.db}_standalone.db" "${DB_FILE}"
        fi
    fi
fi

# Wait until the ovsdb-tool finishes.
trap wait_for_ovsdb_tool EXIT

# don't log to file (we already log to console)
$@ ${OPTS} run_${DB_TYPE}_ovsdb -- -vfile:off &

# Once the database is running, we will attempt to configure db options
CTLCMD="ovn-${DB_TYPE}ctl --no-leader-only"

# Nothing special about the first pod, we just know that it always exists with
# replicas > 0 and use it for configuration. In theory, this could be executed
# in any other pod.
if [[ "$(hostname)" == "{{ .SERVICE_NAME }}-0" ]]; then
    # The command will wait until the daemon is connected and the DB is available
    # All following ctl invocation will use the local DB replica in the daemon
    export OVN_${DB_TYPE^^}_DAEMON=$(${CTLCMD} --pidfile --detach)

{{- if .TLS }}
    ${CTLCMD} set-ssl {{.OVNDB_KEY_PATH}} {{.OVNDB_CERT_PATH}} {{.OVNDB_CACERT_PATH}}
{{- else }}
    ${CTLCMD} del-ssl
{{- end }}
    ${CTLCMD} set-connection ${DB_SCHEME}:${DB_PORT}:${DB_ADDR}

    # OVN does not support setting inactivity-probe through --remote cli arg so
    # we have to set it after database is up.
    #
    # In theory, ovsdb.local-config(5) could be used to configure inactivity
    # probe using a local ovsdb-server. But the future of this database is
    # unclear, and it was largely abandoned by the community in mid-flight, so
    # no tools exist to configure connections using this database. It may even
    # be that this scheme will be abandoned in the future, because its features
    # are covered by ovs text config file support added in latest ovs releases.
    #
    # TODO: Consider migrating inactivity probe setting  to config files when
    # we update to ovs 3.3. See --config-file in ovsdb-server(1) for more
    # details.
    while [ "$(${CTLCMD} get connection . inactivity_probe)" != "{{ .OVN_INACTIVITY_PROBE }}" ]; do
        ${CTLCMD} --inactivity-probe={{ .OVN_INACTIVITY_PROBE }} set-connection ${DB_SCHEME}:${DB_PORT}:${DB_ADDR}
    done
    ${CTLCMD} list connection

    # The daemon is no longer needed, kill it
    kill $(cat $OVN_RUNDIR/ovn-${DB_TYPE}ctl.pid)
    unset OVN_${DB_TYPE^^}_DAEMON
fi

wait_for_ovsdb_tool
trap - EXIT

wait
