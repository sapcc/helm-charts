{{- define "neutron.migration_job_name" -}}
  {{- $bin := include "utils.script.job_finished_hook" . | trim }}
  {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container")  | join "\n" }}
  {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") (include "utils.trust_bundle.volume_mount" . ) (include "utils.trust_bundle.volumes" . ) (include "utils.trust_bundle.env" . )  | join "\n" }}
  {{- $hash := empty .Values.proxysql.mode | ternary $bin $all | sha256sum }}

  {{- .Release.Name }}-migration-{{ substr 0 4 $hash }}-{{ .Values.imageVersion | required "Please set neutron.imageVersion or similar"}}
{{- end }}

{{- define "neutron.aci_config_count" -}}
    {{- $char_limit := int .Values.aci.configmap_char_limit -}}
    {{- $config_data := include (print $.Template.BasePath "/etc/_ml2-conf-aci.ini.tpl") . -}}
    {{- $byte_count := 0 -}}
    {{- $counter := 0 -}}
    {{- range regexSplit "\n\\[" $config_data -1 -}}
        {{- if or (eq $byte_count 0) (ge $byte_count $char_limit) -}}
            {{- $counter = (add $counter 1) -}}
            {{- $byte_count = 0 -}}
        {{- end }}
        {{- $byte_count = (add $byte_count (len .)) }}
    {{- end }}
    {{- $counter -}}
{{- end }}

{{- define "neutron.service_dependencies" }}
  {{- template "neutron.db_service" . }},{{ template "neutron.rabbitmq_service" . }}
{{- end }}

{{- define "neutron.db_service" }}
  {{- include "utils.db_host" . }}
{{- end }}

{{- define "neutron.rabbitmq_service" }}
  {{- .Release.Name }}-rabbitmq
{{- end }}
