{{- define "bind.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bind.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "node_maintenance_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/maintenance-state
                operator: In
                values:
                - operational
{{- end }}

{{- define "node_reinstall_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/deployment-state
                operator: NotIn
                values:
                - reinstalling
{{- end }}

{{/*
Convert the supplied secret_env structure into a name: value list
used by envFrom.secretRef.
*/}}
{{- define "setup_secret_env" -}}
{{- if . }}
{{- range . }}
{{- if .value }}
{{ .name }}: {{ .value | include "resolve_secret" | b64enc }}
{{- else if .template }}
{{ .name }}: {{ include .template.name .template.params | b64enc }}
{{- end }}
{{- end }}
{{- else }}
{}
{{- end }}
{{- end }}

{{/*
Create an rndc/tsig key block
*/}}
{{- define "key" -}}
key "{{.keyname}}" {
 algorithm "{{.algo}}";
 secret "{{.secret}}";
};
{{- end }}

{{/*
base64 encode an rndc/tsig key block
*/}}
{{- define "base64_key" -}}
{{ include "key" . | b64enc }}
{{- end }}
