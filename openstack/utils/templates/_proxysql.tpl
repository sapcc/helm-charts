{{- define "utils.proxysql.volume_mount" }}
  {{- if .Values.proxysql }}
    {{- if .Values.proxysql.mode }}{{/* Always mount it, it doesn't cost much and eases migrations */}}
- mountPath: /run/proxysql
  name: runproxysql
    {{- end }}
  {{- end }}
{{- end }}

{{- define "utils.proxysql.container" }}
  {{- if kindIs "map" . }}
    {{- list . 1 | include "utils.proxysql._container" }}
  {{- else }}
    {{- include "utils.proxysql._container" . }}
  {{- end }}
{{- end }}

{{- define "utils.proxysql._container" }}
  {{- $envAll := index . 0 }}
  {{- $scale := index . 1 | int }}
  {{- with $envAll }}
    {{- if .Values.proxysql }}
      {{- if .Values.proxysql.mode }}
- name: proxysql
  image: {{ if .Values.proxysql.imageRepository -}}
            {{ .Values.proxysql.imageRepository }}
        {{- else -}}
          {{ required ".Values.global.dockerHubMirror is missing" .Values.global.dockerHubMirror }}/{{ default "proxysql/proxysql" .Values.proxysql.image }}
        {{- end }}:{{ .Values.proxysql.imageTag | default "2.4.7-debian" }}
  imagePullPolicy: IfNotPresent
  command: ["proxysql"]
  args: ["--config", "/etc/proxysql/proxysql.cnf", "--exit-on-error", "--foreground", "--idle-threads", "--admin-socket", "/run/proxysql/admin.sock", "--no-version-check", "-D", "/run/proxysql"]
        {{- if gt $scale 1 }}
          {{- $max_pool_size := coalesce .Values.max_pool_size .Values.global.max_pool_size 50 }}
          {{- $max_overflow := coalesce .Values.max_overflow .Values.global.max_overflow 5 }}
          {{- $max_connections := .Values.proxysql.max_connections_per_proc | default (add $max_pool_size $max_overflow) | mul $scale }}
  lifecycle:
    postStart:
      exec:
        command:
        - /bin/bash
        - -c
        - |
          for ((i=0;i<10;++i)); do
            test -S /run/proxysql/admin.sock && break || sleep 1
          done
          for ((i=0;i<10;++i)); do
            mysql --wait -S /run/proxysql/admin.sock -uadmin -padmin -e '
              UPDATE mysql_servers SET max_connections={{ $max_connections }};
              LOAD MYSQL SERVERS TO RUNTIME;
            ' && exit 0 || sleep 1
          done
          exit 1
        {{- end }}
  ports:
  - name: metrics-psql
    containerPort: {{ default 6070 .Values.proxysql.restapi_port }}
  livenessProbe:
    exec:
      command:
      - test
      - -S
      - /run/proxysql/mysql.sock
  volumeMounts:
  - mountPath: /etc/proxysql
    name: etcproxysql
    {{- include "utils.proxysql.volume_mount" . | indent 2 }}
    {{- include "utils.trust_bundle.volume_mount" . | indent 2 }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "utils.proxysql.volumes" }}
  {{- if .Values.proxysql }}
    {{- if .Values.proxysql.mode }}
- name: runproxysql
  emptyDir: {}
- name: etcproxysql
  secret:
    secretName: {{ .Release.Name }}-proxysql-etc
    {{- end }}
  {{- end }}
{{- end }}

# Place this to the pod spec to reroute the traffic via hostAliases
{{- define "utils.proxysql.pod_settings" }}
  {{- if .Values.proxysql }}
    {{- if .Values.proxysql.mode }}
    {{- $envAll := . }}
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
hostAliases:
- ip: "127.0.0.1"
  hostnames:
    {{- range $index, $dbKey := $dbKeys }}
        {{- $db := get $dbs $dbKey }}
  - {{ print $db.name "-mariadb" | quote }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}


# Place this to the pod spec of a job to allow the job to
# stop the sidecar pod via pkill
{{- define "utils.proxysql.job_pod_settings" }}
  {{- if .Values.proxysql }}
    {{- if .Values.proxysql.mode }}
{{- include "utils.proxysql.pod_settings" . }}
shareProcessNamespace: true
securityContext:
  runAsUser: 65534
    {{- end }}
  {{- end }}
{{- end }}

# Place this in job scripts when your script stops normally, but not abnormally
# as this causes the side-car pod finish normally, but we need it for the re-runs
{{- define "utils.proxysql.proxysql_signal_stop_script" }}
  {{- if .Values.proxysql }}
    {{- if .Values.proxysql.mode -}}
pkill proxysql || true
    {{- end }}
  {{- end }}
{{- end }}
