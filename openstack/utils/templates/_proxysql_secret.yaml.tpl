{{- define "proxysql_secret" }}
  {{- $envAll := . }}
  {{- if .Values.proxysql -}}
    {{- if .Values.proxysql.mode -}}
      {{- $max_pool_size := coalesce .Values.max_pool_size .Values.global.max_pool_size 50 }}
      {{- $max_overflow := coalesce .Values.max_overflow .Values.global.max_overflow 5 }}
      {{- $max_connections := .Values.proxysql.max_connections_per_proc | default (add $max_pool_size $max_overflow) }}
      {{/* Default: use mariadb dependencies chart values */}}
      {{- $dbs := dict }}
      {{- range $d := $envAll.Chart.Dependencies }}
        {{- if hasPrefix "mariadb" $d.Name }}
          {{- $_ := set $dbs $d.Name (merge (get $envAll.Values $d.Name) (dict "serviceSuffix" "mariadb")) }}
        {{- end }}
      {{- end }}
      {{/* Option 1: use pxc-db dependencies chart values conditionally */}}
      {{- if and ($envAll.Values.dbType ) (eq $envAll.Values.dbType "pxc-db") }}
        {{- $dbs = dict }}
        {{- range $d := $envAll.Chart.Dependencies }}
          {{- if hasPrefix "pxc" $d.Name }}
            {{- $_ := set $dbs $d.Name (merge (get $envAll.Values $d.Name) (dict "serviceSuffix" "db-haproxy")) }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{/* Option 2: use override from proxysql.force_enable value */}}
      {{- if $envAll.Values.proxysql.force_enable }}
        {{- $dbs = dict }}
        {{- range $d := $envAll.Values.proxysql.force_enable }}
          {{- if hasPrefix "mariadb" $d }}
            {{- $_ := set $dbs $d (merge (get $envAll.Values $d) (dict "serviceSuffix" "mariadb")) }}
          {{- else if hasPrefix "pxc" $d }}
            {{- $_ := set $dbs $d (merge (get $envAll.Values $d) (dict "serviceSuffix" "db-haproxy")) }}
          {{- else }}
            {{ fail (printf "unknown database type: %s" $d) }}
          {{- end }}
        {{- end }}
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
{{ include "utils.snippets.set_proxysql_config" (dict "max_connections" $max_connections "dbs" $dbs "dbKeys" $dbKeys "global" $ ) | b64enc | trim | indent 4 }}
    {{- end }}
  {{- end }}
{{- end }}
