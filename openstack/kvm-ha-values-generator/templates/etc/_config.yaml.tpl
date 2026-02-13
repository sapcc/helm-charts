# Global configuration
{{- if .Values.global.region }}
region: {{ .Values.global.region }}
{{- end }}
{{- if .Values.global.tld }}
tld: {{ .Values.global.tld }}
{{- end }}
{{- if .Values.global.az }}
az: {{ .Values.global.az }}
{{- end }}
{{- if .Values.global.warmup }}
warmup: {{ .Values.global.warmup }}
{{- end }}

{{/* OpenStack section */}}
{{- if .Values.openstack }}
openstack:
  credential:
    auth_url: {{ .Values.openstack.auth_url }}
    username: {{ .Values.openstack.username }}
    {{- if .Values.openstack.password }}
    password: {{ .Values.openstack.password | include "resolve_secret" | quote }}
    {{- end }}
    domain_name: {{ .Values.openstack.domain_name | default "default" }}
    project_domain_name: {{ .Values.openstack.project_domain_name | default "default" }}
    project_name: {{ .Values.openstack.project_name | default "service" }}
  {{- if .Values.openstack.availability }}
  availability: {{ .Values.openstack.availability }}
  {{- end }}
{{- end }}

{{/* Service configuration sections */}}
{{- if .Values.serviceConfig }}

{{- if .Values.serviceConfig.sources }}
sources:
  {{- range .Values.serviceConfig.sources }}
  - name: {{ .name }}
    push: {{ .push }}
    secret: {{ .secret | include "resolve_secret" | quote }}
    url: {{ .url }}
  {{- end }}{{- end }}

{{- if .Values.serviceConfig.source_cache }}
source_cache:
{{- toYaml .Values.serviceConfig.source_cache | nindent 2 }}
{{- end }}

{{- if .Values.serviceConfig.rest }}
rest:
{{- toYaml .Values.serviceConfig.rest | nindent 2 }}
{{- end }}

{{- if .Values.serviceConfig.database }}
database:
{{- toYaml .Values.serviceConfig.database | nindent 2 }}
  {{- if .Values.postgresql }}
  postgres:
    path: postgresql://{{ .Values.postgresql.auth.username | include "resolve_secret" }}:{{ .Values.postgresql.auth.password | include "resolve_secret" }}@{{ .Values.postgresql.path }}/{{ .Values.postgresql.auth.database }}
  {{- end }}
{{- end }}

{{- if .Values.serviceConfig.actions }}
actions:
  {{- if .Values.serviceConfig.actions.slack }}
  slack:
    {{- if .Values.serviceConfig.actions.slack.ignore_errors }}
    ignore_errors: {{ .Values.serviceConfig.actions.slack.ignore_errors }}
    {{- end }}
    data:
      {{- if .Values.serviceConfig.actions.slack.data.channel }}
      channel: {{ .Values.serviceConfig.actions.slack.data.channel | quote }}
      {{- end }}
      {{- if .Values.slack.token }}
      token: {{ .Values.slack.token | include "resolve_secret" | quote }}
      {{- end }}
  {{- end }}
{{- end }}

{{- if .Values.serviceConfig.metrics }}
metrics:
{{- toYaml .Values.serviceConfig.metrics | nindent 2 }}
{{- end }}

{{- if .Values.serviceConfig.templating }}
templating:
  delimiter_left: {{ .Values.serviceConfig.templating.delimiter_left | quote }}
  delimiter_right: {{ .Values.serviceConfig.templating.delimiter_right | quote }}
{{- end }}

{{- if .Values.serviceConfig.hypervisors }}
hypervisors:
  filter: |-
    {{- .Values.serviceConfig.hypervisors.filter | nindent 4 }}
  hypervisor_hostname_pattern: {{ .Values.serviceConfig.hypervisors.hypervisor_hostname_pattern | quote }}
{{- end }}

{{- if .Values.serviceConfig.monitoring }}
monitoring:
{{- toYaml .Values.serviceConfig.monitoring | nindent 2 }}
{{- end }}

{{- end }}

{{/* Prometheus section */}}
{{- if .Values.prometheus }}
prometheus:
{{- toYaml .Values.prometheus | nindent 2 }}
{{- end }}

{{/* Redfish section */}}
{{- if .Values.redfish }}
redfish:
  username: hwconsole
  {{- if .Values.redfish.password }}
  password: {{ .Values.redfish.password | include "resolve_secret" | quote }}
  {{- end }}
  poweroff_poll_interval: 5
  poweroff_poll_timeout: 300
{{- end }}

{{/* Prometheus exports */}}
{{- if .Values.prometheus_exports }}
prometheus_exports:
{{- toYaml .Values.prometheus_exports | nindent 2 }}
{{- end }}
