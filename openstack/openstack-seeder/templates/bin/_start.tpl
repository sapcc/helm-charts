#!/usr/bin/env bash

export http_proxy=
export all_proxy=

{{- if .Values.keystone.authUrl }}
URL_BASE={{ .Values.keystone.authUrl }}
{{- else }}
URL_BASE={{include "keystone_url" .}}
{{- end }}

export OS_AUTH_URL=${URL_BASE}/v3
export OS_AUTH_TYPE=v3password
export OS_USERNAME={{ .Values.keystone.username }}
export OS_PASSWORD={{ .Values.keystone.password }}
{{- if .Values.keystone.userDomainId }}
export OS_USER_DOMAIN_ID={{ .Values.keystone.userDomainId }}
{{- end }}
{{- if .Values.keystone.userDomainName }}
export OS_USER_DOMAIN_NAME={{ .Values.keystone.userDomainName }}
{{- end }}
{{- if .Values.keystone.projectName }}
export OS_PROJECT_NAME={{ .Values.keystone.projectName }}
{{- end }}
{{- if .Values.keystone.projectDomainId }}
export OS_PROJECT_DOMAIN_ID={{ .Values.keystone.projectDomainId }}
{{- end }}
{{- if .Values.keystone.projectDomainName }}
export OS_PROJECT_DOMAIN_NAME={{ .Values.keystone.projectDomainName }}
{{- end }}
{{- if .Values.keystone.domainName }}
export OS_DOMAIN_NAME={{ .Values.keystone.domainName }}
{{- end }}
{{- if .Values.keystone.domainId }}
export OS_DOMAIN_ID={{ .Values.keystone.domainId }}
{{- end }}
export OS_REGION={{.Values.global.region}}

echo "Starting openstack-seeder.."
/usr/local/bin/openstack-seeder --logtostderr --v {{ default 1 .Values.logLevel }} --resync {{ default "24h" .Values.resync | quote }} {{- if .Values.dryRun }} --dry-run{{- end }} {{- range (.Values.ignoreNamespace | splitList ",") }}{{- if . }} --ignorenamespace={{- . }}{{- end }}{{- end }} {{- range (.Values.onlyNamespace | splitList ",") }}{{- if . }} --onlynamespace={{- . }}{{- end }}{{- end }}
