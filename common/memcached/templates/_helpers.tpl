{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default $.Chart.Name $.Values.nameOverride -}}
{{- printf "%s-%s" $.Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/* Generate the service label for the templated Prometheus alerts. */}}
{{- define "alerts.service" -}}
{{- if .Values.alerts.service -}}
{{- .Values.alerts.service -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "dockerHubMirror" -}}
{{- if .Values.use_alternate_registry -}}
{{- .Values.global.dockerHubMirrorAlternateRegion -}}
{{- else -}}
{{- .Values.global.dockerHubMirror -}}
{{- end -}}
{{- end -}}

{{- define "memcached.resolve_secret" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" {{"}}"}}
    {{- else -}}
        {{ $str }}
    {{- end -}}
{{- end -}}

{{/*
Create a string with sasl pwdb secret
This string can't contain a colon symbol (`:`), because:
- the first colon acts as a delimiter between username and password
- the second colon acts as an end of the password
See source: https://github.com/memcached/memcached/blob/1.6.28/sasl_defs.c#L74
Memcached doesn't provide any means to use escaping in the string, so we only have a few options:
- transform username and password with urlquery BOTH in sasl pwdb and oslo.cache [cache]
- remove a colon from the username and password
Note: In oslo.cache services [cache] configuration $ symbol should be escaped as \$ or $$
We've chosen not to use colons in these memcache secrets
*/}}
{{- define "memcached.sasl_pwdb" }}
{{ include "memcached.resolve_secret" .Values.auth.username }}@{{ template "fullname" . }}:{{ include "memcached.resolve_secret" .Values.auth.password }}
{{- end }}

{{- define "memcached_maintenance_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/maintenance-state
                operator: In
                values:
                - operational
{{- end }}

{{- define "memcached_node_reinstall_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/deployment-state
                operator: NotIn
                values:
                - reinstalling
{{- end }}

{{/*
  Generate labels
  $ = global values
  version/noversion = enable/disable version fields in labels
  memcached = desired component name
  job = object type
  config = provided function
  include "memcached.labels" (list $ "version" "memcached" "deployment" "kvstore")
  include "memcached.labels" (list $ "version" "memcached" "job" "config")
*/}}
{{- define "memcached.labels" }}
{{- $ := index . 0 }}
{{- $component := index . 2 }}
{{- $type := index . 3 }}
{{- $function := index . 4 }}
app: {{ template "fullname" $ }}
app.kubernetes.io/name: {{ $.Chart.Name }}
app.kubernetes.io/instance: {{ template "fullname" $ }}
app.kubernetes.io/component: {{ include "label.component" (list $component $type $function) }}
app.kubernetes.io/part-of: {{ $.Release.Name }}
  {{- if eq (index . 1) "version" }}
app.kubernetes.io/version: {{ $.Values.imageTag | regexFind "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" }}
app.kubernetes.io/managed-by: "helm"
helm.sh/chart: {{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}
  {{- end }}
{{- end }}

{{/*
  Generate labels
  memcached = desired component name
  job = object type
  config = provided function
  include "label.component" (list "memcached" "deployment" "kvstore")
  include "label.component" (list "memcached" "job" "config")
*/}}
{{- define "label.component" }}
{{- $component := index . 0 }}
{{- $type := index . 1 }}
{{- $function := index . 2 }}
{{- $component }}-{{ $type }}-{{ $function }}
{{- end }}