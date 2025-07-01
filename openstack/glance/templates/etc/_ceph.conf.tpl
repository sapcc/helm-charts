{{- if .Values.ceph.enabled }}
[global]
fsid = <your-ceph-cluster-fsid>
mon_host = <mon1-ip>,<mon2-ip>,<mon3-ip>
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
log_to_stderr = false
err_to_stderr = false
clog_to_stderr = false
log_file = /var/log/ceph/ceph.log
{{- end }}
