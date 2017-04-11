#!/usr/bin/env bash

export http_proxy=
export all_proxy=

{{- if .Values.keystone.authUrl }}
URL_BASE={{ .Values.keystone.authUrl }}
{{- else }}
URL_BASE={{include "keystone_url" .}}
{{- end }}

#echo "Waiting for the keystone-api ${URL_BASE} to become available.."
#n=1
#m=12
#until [ $n -ge $m ]
#do
#    curl ${URL_BASE} > /dev/null 2>&1  && break
#    echo "Attempt $n of $m waiting 10 seconds to retry"
#    n=$[$n+1]
#    sleep 10
#done
#
#if [ $n -eq $m ]
#then
#    echo "Keystone not available within 120 seconds"
#    exit 1
#fi

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
{{- if .Values.sentry.enabled }}
export SENTRY_DSN={{ .Values.sentry.dsn | quote}}
{{- end }}

echo "Starting openstack-operator.."
/openstack-operator --v 1
