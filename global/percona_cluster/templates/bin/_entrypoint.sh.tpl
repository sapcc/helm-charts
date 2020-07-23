#!/bin/bash
set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

. /startup-scripts/functions.sh

{{- $current_region := .Values.global.db_region -}}
{{- $cluster_ips := values .Values.service.regions }}

{{ range $region, $ip := .Values.service.regions -}}
{{ if eq $region $current_region }}
# the node IP is a K8s service IP, not the K8s pod IP
ipaddr={{ $ip }}
{{- end }}
{{- end }}

# define group segment for geographical awareness
gmcast_segment={{ .Values.gmcast_segment }}


# Cluster IPs are all K8s service IPs
cluster_ips="{{ include "helm-toolkit.utils.joinListWithComma" $cluster_ips }}"
hostname=$(hostname)
echo "I AM $hostname - $ipaddr"

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
    CMDARG="$@"
fi

{{- if eq .Values.service.primary true }}

echo "I am the Primary Node"
init_mysql
write_password_file
exec mysqld --user=mysql --wsrep_cluster_name=$SHORT_CLUSTER_NAME --wsrep_node_name=$hostname-$ipaddr \
--wsrep_cluster_address="gcomm://" --wsrep_sst_method=xtrabackup-v2 \
--wsrep_sst_auth="xtrabackup:$XTRABACKUP_PASSWORD" \
--wsrep_node_address="$ipaddr" --pxc_strict_mode="$PXC_STRICT_MODE" \
--wsrep_provider_options="evs.send_window=128;evs.user_send_window=128;gmcast.segment=$gmcast_segment" \
--log-bin=$hostname-bin $CMDARG

{{- else }}

echo "I am not the Primary Node"
chown -R mysql:mysql /var/lib/mysql || true # default is root:root 777
touch /var/log/mysqld.log
chown mysql:mysql /var/log/mysqld.log
write_password_file
exec mysqld --user=mysql --wsrep_cluster_name=$SHORT_CLUSTER_NAME --wsrep_node_name=$hostname-$ipaddr \
--wsrep_cluster_address="gcomm://{{ include "helm-toolkit.utils.joinListWithComma" $cluster_ips }}" --wsrep_sst_method=xtrabackup-v2 \
--wsrep_sst_auth="xtrabackup:$XTRABACKUP_PASSWORD" \
--wsrep_node_address="$ipaddr" --pxc_strict_mode="$PXC_STRICT_MODE" \
--wsrep_provider_options="evs.send_window=128;evs.user_send_window=128;gmcast.segment=$gmcast_segment" \
--log-bin=$hostname-bin $CMDARG

{{- end }}
