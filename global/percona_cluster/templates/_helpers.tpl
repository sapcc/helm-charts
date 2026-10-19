{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullName" -}}
{{- $name := default "percona-pxc" .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a short cluster name in order to fulfill Percona's `wsrep_cluster_name` variable max size.
https://www.percona.com/doc/percona-xtradb-cluster/LATEST/wsrep-system-index.html#wsrep_cluster_name
*/}}
{{- define "percona-cluster.shortname" -}}
{{- $name := default "pxc" .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 32 | trimSuffix "-" -}}
{{- end -}}

{{- define "percona-cluster.resolve_secret_squote" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" | replace "'" "''" | squote {{"}}"}}
    {{- else -}}
        {{ $str | replace "'" "''" | squote }}
{{- end -}}
{{- end -}}

{{/* Helper to turn list into a comma-separated string */}}
{{- define "helm-toolkit.utils.joinListWithComma" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}{{- if not $local.first -}},{{- end -}}{{- $v -}}{{- $_ := set $local "first" false -}}{{- end -}}
{{- end -}}

{{/* Generate the service label for the templated Prometheus alerts. */}}
{{- define "alerts.service" -}}
{{- if .Values.alerts.service -}}
{{- .Values.alerts.service -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "pxc_maintenance_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/maintenance-state
                operator: In
                values:
                - operational
{{- end }}

{{- define "pxc_node_reinstall_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/deployment-state
                operator: NotIn
                values:
                - reinstalling
{{- end }}
