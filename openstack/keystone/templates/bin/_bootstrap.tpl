#!/usr/bin/env bash
set -e

# Bootstrap failures are temporarily non-fatal for Helm deployments.
echo "Running native Keystone bootstrap"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf bootstrap \
    --bootstrap-username {{ .Values.api.adminUser }} \
    --bootstrap-password {{ required "A valid .Values.api.adminPassword required!" .Values.api.adminPassword | include "resolve_secret" }} \
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
{{- if .Values.global.is_global_region }}
    --bootstrap-internal-url http://{{ .Values.global.keystone_internal_ip }}:5000/v3 \
{{- else }}
    --bootstrap-internal-url http://{{ include "keystone_api_endpoint_host_internal" . }}:5000/v3 \
{{- end }}
    --bootstrap-region-id {{ .Values.global.region }} ||
    echo "ERROR: Native Keystone bootstrap failed with exit code $?; ignoring failure." >&2

echo "Running Keystone extensions bootstrap"
keystone-manage-extension --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf bootstrap \
    --bootstrap-file=/etc/keystone/bootstrap.yaml ||
    echo "ERROR: Keystone extensions bootstrap failed with exit code $?; ignoring failure." >&2

{{ include "utils.script.job_finished_hook" . | trim }}
