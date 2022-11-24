{{/* Generated objectStorageConfigName */}}
{{- define "thanos.objectStorageConfigName" -}}
prometheus-{{- required ".Values.name" .Values.name -}}-thanos-storage-config
{{- end -}}

{{/* Thanos image. */}}
{{- define "thanosimage" -}}
{{- required ".Values.spec.baseImage missing" .Values.spec.baseImage -}}:{{- required ".Chart.appVersion missing" .Chart.AppVersion -}}
{{- end -}}

{{/* Thanos name */}}
{{- define "thanos.name" -}}
{{- required ".Values.name" .Values.name -}}
{{- end -}}

{{/* Thanos combined name */}}
{{- define "thanos.fullName" -}}
thanos-{{- required ".Values.name" .Values.name -}}
{{- end -}}

{{/* External URL of this Thanos. Copied from prometheus-server */}}
{{- define "thanos.externalURL" -}}
{{- if and .Values.ingress.hosts .Values.ingress.hostsFQDN -}}
{{- fail ".Values.ingress.hosts and .Values.ingress.hostsFQDN are mutually exclusive." -}}
{{- end -}}
{{- if .Values.ingress.hosts -}}
{{- $firstHost := first .Values.ingress.hosts -}}
{{- required ".Values.ingress.hosts must have at least one hostname set" $firstHost -}}.{{- required ".Values.global.region missing" .Values.global.region -}}.{{- required ".Values.global.tld missing" .Values.global.tld -}}
{{- else -}}
{{- $firstHost := first .Values.ingress.hostsFQDN -}}
{{- required ".Values.ingress.hostsFQDN must have at least one hostname set" $firstHost -}}
{{- end -}}
{{- end -}}

{{/* gRPC URL of this Thanos. */}}
{{- define "thanos.grpcURL" -}}
{{- if and .Values.grpcIngress.hosts .Values.grpcIngress.hostsFQDN -}}
{{- fail ".Values.grpcIngress.hosts and .Values.grpcIngress.hostsFQDN are mutually exclusive." -}}
{{- end -}}
{{- if .Values.grpcIngress.hosts -}}
{{- $firstHost := first .Values.grpcIngress.hosts -}}
{{- required ".Values.grpcIngress.hosts must have at least one hostname set" $firstHost -}}-grpc.{{- required ".Values.global.region missing" .Values.global.region -}}.{{- required ".Values.global.tld missing" .Values.global.tld -}}
{{- else -}}
{{- $firstHost := first .Values.ingress.hostsFQDN -}}
{{- required ".Values.grpcIngress.hostsFQDN must have at least one hostname set" $firstHost -}}
{{- end -}}
{{- end -}}
