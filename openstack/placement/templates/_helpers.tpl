{{- define "placement.job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $all := list (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") (include "utils.trust_bundle.volume_mount" . ) (include "utils.trust_bundle.volumes" .) | join "\n" }}
    {{- $hash := empty .Values.proxysql.mode | ternary "" $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.imageVersion | required "Please set .imageVersion or similar"}}
  {{- end }}
{{- end }}


{{- define "placement.db_name" }}
  {{- if or (eq .Values.dbType "mariadb") (eq .Values.dbType "pxc-db") }}
{{- include "utils.db_host" . -}}
{{/* Use nova-api-mariadb database, if no database is selected explicitly */}}
  {{- else -}}
"nova-api-mariadb"
  {{- end }}
{{- end }}
