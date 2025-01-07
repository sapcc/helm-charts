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

{{define "keystone_url"}}http://keystone.{{ default .Release.Namespace .Values.global.keystoneNamespace }}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3{{end}}

{{- define "mariadb.db_host"}}{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{- end}}

{{- define "mariadb.resolve_secret" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" {{"}}"}}
    {{- else -}}
        {{ $str }}
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

{{- define "mariadb.root_password" -}}
{{- include "mariadb.resolve_secret" (required ".Values.root_password missing" .Values.root_password) }}
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