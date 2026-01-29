#!/usr/bin/env bash

export http_proxy=
export all_proxy=

echo "Starting openstack-seeder.."
/usr/local/bin/openstack-seeder --logtostderr --v {{ default 1 .Values.logLevel }} --resync {{ default "24h" .Values.resync | quote }} {{- if .Values.dryRun }} --dry-run{{- end }} {{- range (.Values.ignoreNamespace | splitList ",") }}{{- if . }} --ignorenamespace={{- . }}{{- end }}{{- end }} {{- range (.Values.onlyNamespace | splitList ",") }}{{- if . }} --onlynamespace={{- . }}{{- end }}{{- end }}
