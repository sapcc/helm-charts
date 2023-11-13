{{- define "neutron.migration_job_name" -}}
  {{- $bin := include "utils.proxysql.proxysql_signal_stop_script" . | trim }}
  {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container")  | join "\n" }}
  {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") (include "utils.trust_bundle.volume_mount" . ) (include "utils.trust_bundle.volumes" . ) (include "utils.trust_bundle.env" . )  | join "\n" }}
  {{- $hash := empty .Values.proxysql.mode | ternary $bin $all | sha256sum }}

  {{- .Release.Name }}-migration-{{ substr 0 4 $hash }}-{{ .Values.imageVersion | required "Please set neutron.imageVersion or similar"}}
{{- end }}
