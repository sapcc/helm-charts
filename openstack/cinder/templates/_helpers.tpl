{{- define "cinder.migration_job_name" -}}
{{- $bin := include "utils.proxysql.proxysql_signal_stop_script" . | trim }}
{{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") (include "utils.trust_bundle.volume_mount" . ) (include "utils.trust_bundle.volumes" . )  | join "\n" }}
{{- $hash := empty .Values.proxysql.mode | ternary $bin $all | sha256sum }}
{{- .Release.Name }}-migration-job-{{ substr 0 4 $hash }}-{{ .Values.imageVersion | required "Please set cinder.imageVersion or similar" }}
{{- end }}
