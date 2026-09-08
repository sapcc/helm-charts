{{- define "manila_type_seed.specs" }}
driver_handles_share_servers: true
snapshot_support: true
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

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $bin := include (print .Template.BasePath "/bin/_db_migrate.sh.tpl") . }}
    {{- $all := list $bin
          (include (print .Template.BasePath "/etc-configmap.yaml") .)
          (include (print .Template.BasePath "/secrets.yaml") .)
          (include "utils.proxysql.job_pod_settings" .)
          (include "utils.proxysql.volume_mount" .)
          (include "utils.proxysql.container" .)
          (include "utils.proxysql.volumes" .)
          (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container")
      | join "\n" }}
    {{- $hash := empty .Values.proxysql.mode | ternary $bin $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.loci.imageVersion | required "Please set manila.loci.imageVersion" }}
  {{- end }}
{{- end }}
