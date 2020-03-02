#!/bin/bash
set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

. /startup-scripts/functions.sh


{{- $cluster_ips := "" }}

{{ range $region, $ip := .Values.service.percona.regions -}}

{{ if eq .Values.global.region $region }}
# the node IP is a service IP
ipaddr={{ $ip }}
{{- end }}

# the IP list of all nodes
{{- $cluster_ips := (printf "%v,%v" $cluster_ips $ip) }}
{{- end }}

cluster_ips={{ $cluster_ips }}
hostname=$(hostname)
echo "I AM $hostname - $ipaddr"

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
    CMDARG="$@"
fi

{{- if eq .Values.service.percona.primary true }}

echo "I am the Primary Node"
init_mysql
write_password_file
exec mysqld --user=mysql --wsrep_cluster_name=$SHORT_CLUSTER_NAME --wsrep_node_name=$hostname \
--wsrep_cluster_address=gcomm:// --wsrep_sst_method=xtrabackup-v2 \
--wsrep_sst_auth="xtrabackup:$XTRABACKUP_PASSWORD" \
--wsrep_node_address="$ipaddr" --pxc_strict_mode="$PXC_STRICT_MODE" $CMDARG

{{- else }}

echo "I am not the Primary Node"
chown -R mysql:mysql /var/lib/mysql || true # default is root:root 777
touch /var/log/mysqld.log
chown mysql:mysql /var/log/mysqld.log
write_password_file
exec mysqld --user=mysql --wsrep_cluster_name=$SHORT_CLUSTER_NAME --wsrep_node_name=$hostname \
--wsrep_cluster_address="gcomm://$cluster_ips" --wsrep_sst_method=xtrabackup-v2 \
--wsrep_sst_auth="xtrabackup:$XTRABACKUP_PASSWORD" \
--wsrep_node_address="$ipaddr" --pxc_strict_mode="$PXC_STRICT_MODE" $CMDARG

{{- end }}
