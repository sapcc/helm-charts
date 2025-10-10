{{- if .Values.ceph.enabled }}
[global]
fsid = {{ .Values.ceph.fsid }}
mon_host = {{ .Values.ceph.mon_host }}
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
keyring = /etc/glance/ceph.client.glance.keyring
{{- end }}
