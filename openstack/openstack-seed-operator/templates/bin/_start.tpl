#!/usr/bin/env bash

export http_proxy=
export all_proxy=

{{- if .Values.os_auth_url }}
URL_BASE={{ .Values.os_auth_url }}
{{- else }}
URL_BASE=http://keystone-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.region}}.{{.Values.tld}}:5000
{{- end }}

echo "Waiting for the keystone-api ${URL_BASE} to become available.."

n=1
m=12
until [ $n -ge $m ]
do
    curl ${URL_BASE} > /dev/null 2>&1  && break
    echo "Attempt $n of $m waiting 10 seconds to retry"
    n=$[$n+1]
    sleep 10
done

if [ $n -eq $m ]
then
    echo "Keystone not available within 120 seconds"
    exit 1
fi

export OS_AUTH_URL=${URL_BASE}/v3
export OS_AUTH_TYPE=v3password
export OS_USERNAME={{ .Values.os_username }}
export OS_PASSWORD={{ .Values.os_password }}
{{- if .Values.os_user_domain_id }}
export OS_USER_DOMAIN_ID={{ .Values.os_user_domain_id }}
{{- end }}
{{- if .Values.os_user_domain_name }}
export OS_USER_DOMAIN_NAME={{ .Values.os_user_domain_name }}
{{- end }}
{{- if .Values.os_project_name }}
export OS_PROJECT_NAME={{ .Values.os_project_name }}
{{- end }}
{{- if .Values.os_project_domain_id }}
export OS_PROJECT_DOMAIN_ID={{ .Values.os_project_domain_id }}
{{- end }}
{{- if .Values.os_project_domain_name }}
export OS_PROJECT_DOMAIN_NAME={{ .Values.os_project_domain_name }}
{{- end }}
{{- if .Values.os_domain_name }}
export OS_DOMAIN_NAME={{ .Values.os_domain_name }}
{{- end }}
{{- if .Values.os_domain_id }}
export OS_DOMAIN_ID={{ .Values.os_domain_id }}
{{- end }}
export OS_REGION={{.Values.region}}
{{- if .Values.sentry.enabled }}
export SENTRY_DSN={{ .Values.sentry.dsn | quote}}
{{- end }}

echo "Starting openstack-operator.."
/openstack-operator --v 1
