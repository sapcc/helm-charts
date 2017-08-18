#!/usr/bin/env bash

set -ex

# seed just enough to have a functional v3 api
keystone-manage-extension --config-file=/etc/keystone/keystone.conf bootstrap \
    --bootstrap-username {{ .Values.api.adminUser }} \
    --bootstrap-password {{ .Values.api.adminPassword }} \
    --bootstrap-project-name {{ .Values.api.adminProjectName }} \
{{- if eq .Values.services.admin.scheme "https" }}
    --bootstrap-admin-url https://{{.Values.services.admin.host}}/v3 \
{{- else }}
    --bootstrap-admin-url {{.Values.services.admin.scheme}}://{{.Values.services.admin.host}}:{{.Values.services.admin.port}}/v3 \
{{- end }}
{{- if eq .Values.services.public.scheme "https" }}
    --bootstrap-public-url https://{{.Values.services.public.host}}/v3 \
{{- else }}
    --bootstrap-public-url {{.Values.services.public.scheme}}://{{.Values.services.public.host}}:{{.Values.services.public.port}}/v3 \
{{- end }}
    --bootstrap-internal-url http://keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3 \
    --bootstrap-region-id {{ .Values.global.region }}