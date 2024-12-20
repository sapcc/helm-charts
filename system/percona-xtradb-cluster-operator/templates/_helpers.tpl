{{- define "percona-xtradb-cluster-operator.labels" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}-{{ .Chart.Name }}
app.kubernetes.io/part-of: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: "helm"
helm.sh/chart: {{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}
{{- end }}

{{/*
Override function returns image URI according to parameters set
*/}}
{{- define "pxc-operator.image" -}}
{{- if .Values.image }}
{{- .Values.image }}
{{- else if .Values.imageTag }}
{{- printf "%s:%s" .Values.operatorImageRepository .Values.imageTag }}
{{- else }}
{{- printf "%s:%s" .Values.operatorImageRepository .Chart.AppVersion }}
{{- end }}
{{- end -}}
