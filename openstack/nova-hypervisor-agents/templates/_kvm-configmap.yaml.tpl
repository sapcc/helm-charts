{{- define "kvm_configmap" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-compute
  labels:
    system: openstack
    type: configuration
    component: nova
data:
  nova-compute.conf: |
    {{ include (print .Template.BasePath "/etc/_nova-compute.conf.tpl") . | nindent 4 }}
  libvirtd.conf: |
    listen_tcp = 1
    listen_tls = 0
    mdns_adv = 0
    auth_tcp = "none"
    ca_file = ""
    log_level = 3
    log_outputs = "3:stderr"
    listen_addr = "127.0.0.1"
    live_migration_inbound_addr = $my_ip
{{- end }}
