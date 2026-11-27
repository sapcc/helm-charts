{{- define "neutron.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}

{{- define "neutron.image.digest" -}}
{{- $parts := splitList "@" (toString .) -}}
{{- if gt (len $parts) 1 -}}
{{- index $parts 1 -}}
{{- end -}}
{{- end -}}

{{- define "neutron.migration_job_name" -}}
  {{- $pin := .Values.imageVersion | required "Please set neutron.imageVersion or similar" }}
  {{- $tag := include "neutron.image.tag" $pin }}
  {{- $digest := include "neutron.image.digest" $pin }}
  {{- $bin := include "utils.script.job_finished_hook" . | trim }}
  {{- $all := list $bin (include "utils.linkerd.pod_and_service_annotation" .) (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") (include "utils.trust_bundle.volume_mount" . ) (include "utils.trust_bundle.volumes" . ) (include "utils.trust_bundle.env" . )  | join "\n" }}
  {{- $hashInput := empty .Values.proxysql.mode | ternary $bin $all }}
  {{- if $digest }}
    {{- $hashInput = printf "%s\n%s" $hashInput $digest }}
  {{- end }}
  {{- $hash := $hashInput | sha256sum }}
  {{- if $digest }}
    {{- /* Budget the readable prefix first, retaining the migration/hash suffix. */ -}}
    {{- $suffix := printf "-migration-%s" (substr 0 4 $hash) }}
    {{- $prefix := regexReplaceAll "[^a-z0-9-]" (printf "%s-%s" .Release.Name $tag | lower) "-" | trimAll "-" }}
    {{- $prefix = $prefix | trunc (int (sub 63 (len $suffix))) | trimSuffix "-" }}
    {{- printf "%s%s" $prefix $suffix }}
  {{- else }}
    {{- .Release.Name }}-migration-{{ substr 0 4 $hash }}-{{ $tag }}
  {{- end }}
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
