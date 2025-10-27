{{/* Generate the full name. */}}
{{- define "fullName" -}}
{{- required ".Values.name missing" .Values.name -}}-mariadb
{{- end -}}

{{/* Generate the service label for the templated Prometheus alerts. */}}
{{- define "alerts.service" -}}
{{- if .Values.alerts.service -}}
{{- .Values.alerts.service -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "mariadb.resolve_secret_squote" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" | replace "'" "''" | squote {{"}}"}}
    {{- else -}}
        {{ $str | replace "'" "''" | squote }}
{{- end -}}
{{- end -}}

{{- define "registry" -}}
{{- if .Values.use_alternate_registry -}}
{{- .Values.global.registryAlternateRegion -}}
{{- else -}}
{{- .Values.global.registry -}}
{{- end -}}
{{- end -}}

{{- define "dockerHubMirror" -}}
{{- if .Values.use_alternate_registry -}}
{{- .Values.global.dockerHubMirrorAlternateRegion -}}
{{- else -}}
{{- .Values.global.dockerHubMirror -}}
{{- end -}}
{{- end -}}

{{- define "mariadb_maintenance_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/maintenance-state
                operator: In
                values:
                - operational
{{- end }}

{{- define "mariadb_node_reinstall_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/deployment-state
                operator: NotIn
                values:
                - reinstalling
{{- end }}

{{/* Needed for testing purposes only. */}}
{{define "RELEASE-NAME_db_host"}}testRelease-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "testRelease_db_host"}}testRelease-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{/*
Charts owner-info labels
*/}}
{{- define "mariadb.ownerLabels" -}}
{{- if index .Values "owner-info" }}
ccloud/support-group: {{  index .Values "owner-info" "support-group" | quote }}
ccloud/service: {{  index .Values "owner-info" "service" | quote }}
{{- end }}
{{- end }}

{{/*
  Generate labels
  $ = global values
  version/noversion = enable/disable version fields in labels
  mariadb = desired component name
  job = object type
  config = provided function
  include "mariadb.labels" (list $ "version" "mariadb" "deployment" "database")
  include "mariadb.labels" (list $ "version" "mariadb" "job" "config")
*/}}
{{- define "mariadb.labels" }}
{{- $ := index . 0 }}
{{- $component := index . 2 }}
{{- $type := index . 3 }}
{{- $function := index . 4 }}
app.kubernetes.io/name: {{ $.Chart.Name }}
app.kubernetes.io/instance: {{ $.Release.Name }}-{{ $.Chart.Name }}
app.kubernetes.io/component: {{ include "label.component" (list $component $type $function) }}
app.kubernetes.io/part-of: {{ $.Release.Name }}
  {{- if eq (index . 1) "version" }}
app.kubernetes.io/version: {{ $.Values.image | regexFind "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" }}
app.kubernetes.io/managed-by: "helm"
helm.sh/chart: {{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}
  {{- end }}
{{- end }}

{{/*
  Generate labels
  mariadb = desired component name
  job = object type
  config = provided function
  include "label.component" (list "mariadb" "deployment" "database")
  include "label.component" (list "mariadb" "job" "config")
*/}}
{{- define "label.component" }}
{{- $component := index . 0 }}
{{- $type := index . 1 }}
{{- $function := index . 2 }}
{{- $component }}-{{ $type }}-{{ $function }}
{{- end }}

{{/*
  generate a randomized schedule for the maintenance job
  include "mariadb.maintenance.schedule.randomize"
*/}}
{{- define "mariadb.maintenance.schedule.randomize" }}
  {{- if $.Values.job.maintenance.schedule -}}
    {{- $schedule := split " " $.Values.job.maintenance.schedule }}
    {{- $minute := required "invalid cron syntax for job.maintenance.schedule" $schedule._0 }}
    {{- $hour := required "invalid cron syntax for job.maintenance.schedule" $schedule._1 }}
    {{- $monthday := required "invalid cron syntax for job.maintenance.schedule" $schedule._2 }}
    {{- $month := required "invalid cron syntax for job.maintenance.schedule" $schedule._3 }}
    {{- $weekday := required "invalid cron syntax for job.maintenance.schedule" $schedule._4 }}
    {{- if not (mustRegexMatch "^(\\*|\\?)$|^(\\*|\\?)\\/[0-9]{1,2}$|^[0-9]{1,2}-[0-9]{1,2}$" $minute) }}
      {{- $minute = (randInt 1 59 | toString) }}
    {{- end }}
    {{- (printf "%s %s %s %s %s" $minute $hour $monthday $month $weekday) }}
  {{- else -}}
    {{- (printf "%d %d * * %d" (randInt 1 59) (randInt 9 15) (randInt 2 4)) }}
  {{- end }}
{{- end }}

{{/*
Default pod labels for linkerd
*/}}
{{- define "mariadb.linkerdPodAnnotations" }}
  {{- if and (and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested) $.Values.linkerd.mariadb.enabled }}
linkerd.io/inject: enabled
    {{- if $.Values.global.linkerd_use_native_sidecar }}
config.alpha.linkerd.io/proxy-enable-native-sidecar: "true"
    {{- end }}
  {{- end }}
{{- end }}
