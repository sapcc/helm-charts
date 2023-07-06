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
netapp:max_files_multiplier: "4.813"  # 33.6925 / 7 -> roughly 1 inode per 7 KB
netapp:snapshot_policy: "none"
netapp:split_clone_on_create: "True"
netapp:tcp_max_xfer_size: "262144"  # ccloud 256 KB, system default for ONTAP 9.5 was 64 KB
netapp:thin_provisioned: "True"     # netapp_flexvol_encryption: "True"
create_share_from_snapshot_support: "True"
revert_to_snapshot_support: "True"
replication_type: "dr"
provisioning:max_share_size: "16384"
provisioning:max_share_extend_size: "20480" # keep this in sync with value "max_asset_sizes" of "- asset_type: 'nfs-shares.*'" in openstack/castellum/templates/configmap.yaml
{{- end }}
