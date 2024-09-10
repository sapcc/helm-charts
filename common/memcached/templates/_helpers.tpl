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
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
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
{{- define "memcached.sasl_pwdb" -}}
{{ include "memcached.resolve_secret" .Values.auth.username }}:{{ include "memcached.resolve_secret" .Values.auth.password }}
{{- end -}}

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

{{- define "sharedservices.labels" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Chart.Name }}-{{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}
app.kubernetes.io/component: {{ .Chart.Name }}
app.kubernetes.io/part-of: {{ .Release.Name }}
{{- end }}
