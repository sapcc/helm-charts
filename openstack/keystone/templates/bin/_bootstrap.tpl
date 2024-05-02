#!/usr/bin/env bash
set -ex

# seed just enough to have a functional v3 api
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf bootstrap \
    --bootstrap-username {{ .Values.api.adminUser }} \
    --bootstrap-password {{ required "A valid .Values.api.adminPassword required!" .Values.api.adminPassword }} \
    --bootstrap-project-name {{ .Values.api.adminProjectName }} \
{{- if eq .Values.services.admin.scheme "https" }}
    --bootstrap-admin-url https://{{.Values.services.admin.host}}.{{.Values.global.region}}.{{.Values.global.tld}}/v3 \
{{- else }}
    --bootstrap-admin-url {{.Values.services.admin.scheme}}://{{.Values.services.admin.host}}.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3 \
{{- end }}
{{- if eq .Values.services.public.scheme "https" }}
    --bootstrap-public-url https://{{.Values.services.public.host}}.{{.Values.global.region}}.{{.Values.global.tld}}/v3 \
{{- else }}
    --bootstrap-public-url {{.Values.services.public.scheme}}://{{.Values.services.public.host}}.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3 \
{{- end }}
{{- if .Values.global.clusterDomain }}
    --bootstrap-internal-url http://keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}:5000/v3 \
{{- else if .Values.global_setup }}
    --bootstrap-internal-url http://{{ .Values.global.keystone_internal_ip }}:5000/v3 \
{{- else }}
    --bootstrap-internal-url http://keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3 \
{{- end }}
    --bootstrap-region-id {{ .Values.global.region }}

{{ include "utils.script.job_finished_hook" . | trim }}
