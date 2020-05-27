#!/usr/bin/env bash

set -e

. /container.init/common.sh

manila-status --config-file /etc/manila/manila.conf upgrade check
manila-manage db sync
manila-manage service cleanup

{{- if required ".Values.global.netapp is missing" .Values.global.netapp }}
{{- if .Values.global.netapp.filers }}
{{- range $i, $share := .Values.global.netapp.filers }}
manila-manage share update_host --currenthost manila-share-netapp-{{$share.name}}@netapp-multi --newhost manila-share-netapp-{{$share.name}}@{{$share.name}}
{{- end -}}
{{- end -}}
{{- end -}}
