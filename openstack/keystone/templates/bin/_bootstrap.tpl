#!/usr/bin/env bash

set -ex

# seed just enough to have a functional v3 api
keystone-manage-extension --config-file=/etc/keystone/keystone.conf bootstrap \
    --bootstrap-username {{ .Values.keystone.adminUser }} \
    --bootstrap-password {{ .Values.keystone.adminPassword }} \
    --bootstrap-project-name {{ .Values.keystone.adminProjectName }} \
    --bootstrap-admin-url {{.Values.services.admin.scheme}}://{{.Values.services.admin.host}}:{{.Values.services.admin.port}}/v3 \
    --bootstrap-public-url {{.Values.services.public.scheme}}://{{.Values.services.public.host}}:{{.Values.services.public.port}}/v3 \
    --bootstrap-internal-url http://keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.region}}.{{.Values.tld}}:5000/v3 \
    --bootstrap-region-id {{ .Values.region }}