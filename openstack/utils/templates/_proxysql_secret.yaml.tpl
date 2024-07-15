{{- define "proxysql_secret" }}
  {{- $envAll := . }}
  {{- if .Values.proxysql -}}
    {{- if .Values.proxysql.mode -}}
      {{- $max_pool_size := coalesce .Values.max_pool_size .Values.global.max_pool_size 50 }}
      {{- $max_overflow := coalesce .Values.max_overflow .Values.global.max_overflow 5 }}
      {{- $max_connections := .Values.proxysql.max_connections_per_proc | default (add $max_pool_size $max_overflow) }}

      {{- $dbs := dict }}
      {{- range $d := $envAll.Chart.Dependencies }}
        {{- if hasPrefix "mariadb" $d.Name }}
          {{- $_ := set $dbs $d.Name (get $envAll.Values $d.Name) }}
        {{- end }}
      {{- end }}
      {{- range $d := $envAll.Values.proxysql.force_enable }}
        {{- $_ := set $dbs $d (get $envAll.Values $d) }}
      {{- end }}
      {{- $dbKeys := keys $dbs | sortAlpha }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-proxysql-etc
  labels:
    system: openstack
    type: configuration
    component: database
  {{- if .Values.proxysql.forceSecretCreation }}
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "-10"
  {{- end }}
data:
  proxysql.cnf: |
{{ include "utils.snippets.set_proxysql_config" (dict "max_connections" $max_connections "dbs" $dbs "dbKeys" $dbKeys "global" $ )  | b64enc | trim | indent 4 }}
    {{- end }}
  {{- end }}
{{- end }}
