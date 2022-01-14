{{- define "memcached_host" }}
{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end}}
{{- define "manila_type_seed.specs" }}
driver_handles_share_servers: true
snapshot_support: true
{{- end }}
{{- define "manila_type_seed.extra_specs" }}
compression: "<is> True"
dedupe: "<is> True"
netapp:hide_snapdir: "True"
netapp:snapshot_policy: "none"
netapp:split_clone_on_create: "True"
netapp:tcp_max_xfer_size: "262144"  # ccloud 256 KB, system default for ONTAP 9.5 was 64 KB
netapp:thin_provisioned: "True"
create_share_from_snapshot_support: "True"
revert_to_snapshot_support: "True"
replication_type: "dr"
provisioning:max_share_size: "16384"  # 16 TB
{{- end }}
