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

{{- define "rabbitmq.resolve_secret_urlquery" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" | urlquery {{"}}"}}
    {{- else -}}
        {{ $str }}
{{- end -}}
{{- end -}}

{{define "rabbitmq.release_host"}}{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{- define "rabbitmq.transport_url" -}}{{ tuple . .Values.rabbitmq | include "rabbitmq._transport_url" }}{{- end}}

{{- define "rabbitmq._transport_url" -}}
{{- $envAll := index . 0 -}}
{{- $rabbitmq := index . 1 -}}
{{- $_prefix := default "" $envAll.Values.global.user_suffix -}}
{{- $_username := include "rabbitmq.resolve_secret_urlquery" (required "$rabbitmq.users.default.user missing" $rabbitmq.users.default.user) -}}
{{- $_password := include "rabbitmq.resolve_secret_urlquery" (required "$rabbitmq.users.default.password missing" $rabbitmq.users.default.password) -}}
{{- $_rhost := include "rabbitmq.release_host" $envAll -}}
rabbit://{{- $_prefix -}}{{- $_username -}}:{{- $_password -}}@{{- $_rhost -}}:{{ $rabbitmq.port | default 5672 }}{{ $rabbitmq.virtual_host | default "/" }}
{{- end}}

{{- define "rabbitmq.default_user" -}}
default_user = {{ include "rabbitmq.resolve_secret_urlquery" .Values.users.default.user }}
default_pass = {{ include "rabbitmq.resolve_secret_urlquery" .Values.users.default.password }}
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

{{- define "rabbitmq_maintenance_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/maintenance-state
                operator: In
                values:
                - operational
{{- end }}

{{- define "rabbitmq_node_reinstall_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/deployment-state
                operator: NotIn
                values:
                - reinstalling
{{- end }}
