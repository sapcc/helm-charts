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
{{- end }}

{{/*
Define the Manila API dependency services for kubernetes-entrypoint init container
memcached is being used only by API via keystoneauth
*/}}
{{- define "manila.api_service_dependencies" }}
  {{- template "manila.db_service" . }},{{ template "manila.rabbitmq_service" . }},{{ template "manila.memcached_service" . }}
{{- end }}

{{/*
Define the Manila dependency services for kubernetes-entrypoint init container
*/}}
{{- define "manila.service_dependencies" }}
  {{- template "manila.db_service" . }},{{ template "manila.rabbitmq_service" . }}
{{- end }}

{{- define "manila.db_service" }}
  {{- include "utils.db_host" . }}
{{- end }}

{{- define "manila.rabbitmq_service" }}
  {{- .Release.Name }}-rabbitmq
{{- end }}

{{- define "manila.memcached_service" }}
  {{- .Release.Name }}-memcached
{{- end }}
