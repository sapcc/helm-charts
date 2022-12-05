{{/* Thanos image. */}}
{{- define "thanosimage" -}}
{{- required ".Values.spec.baseImage missing" .Values.spec.baseImage -}}:{{- required ".Chart.appVersion missing" .Chart.AppVersion -}}
{{- end -}}

{{/* Thanos name */}}
{{- define "thanos.name" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if and (not $root.Values.names) (not $root.Values.global.targets) (not $root.Values.name) -}}
{{- fail "Cannot create any Thanos resource. Please define a name or at least one list element to names or global.targets" -}}
{{- end -}}
{{- if $root.Values.vmware -}}
{{- $vropshostname := split "." $name -}}
vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- else -}}
{{- $name -}}
{{- end -}}
{{- end -}}

{{/* Thanos combined name */}}
{{- define "thanos.fullName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if $root.Values.vmware -}}
{{- $vropshostname := split "." $name -}}
thanos-vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- else -}}
thanos-{{- $name -}}
{{- end -}}
{{- end -}}

{{/* External URL of this Thanos. */}}
{{- define "thanos.externalURL" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if and $root.Values.ingress.hosts $root.Values.ingress.hostsFQDN -}}
{{- fail ".Values.ingress.hosts and .Values.ingress.hostsFQDN are mutually exclusive." -}}
{{- end -}}
{{- if $root.Values.ingress.hosts -}}
{{- $firstHost := first $root.Values.ingress.hosts -}}
{{- required ".Values.ingress.hosts must have at least one hostname set" $firstHost -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.domain missing" $root.Values.global.domain -}}
{{- else if $root.Values.ingress.hostsFQDN -}}
{{- $firstHost := first $root.Values.ingress.hostsFQDN -}}
{{- required ".Values.ingress.hostsFQDN must have at least one hostname set" $firstHost -}}
{{- else -}}
thanos-{{- $name -}}.{{- required "$root.Values.global.region missing" $root.Values.global.region -}}.{{- required "$root.Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{/* External gRPC URL of this Thanos. */}}
{{- define "thanos.externalGrpcURL" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if and $root.Values.ingress.hosts $root.Values.ingress.hostsFQDN -}}
{{- fail ".Values.ingress.hosts and .Values.ingress.hostsFQDN are mutually exclusive." -}}
{{- end -}}
thanos-{{- $name -}}-grpc.{{- required "$root.Values.global.region missing" $root.Values.global.region -}}.{{- required "$root.Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}

{{- define "fqdnHelper" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- if not $root.Values.ingress.hosts -}}
thanos-{{- $host -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- else -}}
{{- $host -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{- define "grpcFqdnHelper" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- if not $root.Values.grpcIngress.hosts -}}
thanos-{{- $host -}}-grpc.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- else -}}
{{- $host -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{- define "thanos.objectStorageConfigName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
prometheus-{{- include "thanos.name" . -}}-thanos-storage-config
{{- end -}}

{{- define "thanos.defaultRelabelConfig" -}}
- action: replace
  targetLabel: region
  replacement: {{ required ".Values.global.region missing" .Values.global.region }}
- action: replace
  targetLabel: cluster_type
  replacement: {{ required ".Values.global.clusterType missing" .Values.global.clusterType }}
- action: replace
  targetLabel: cluster
  replacement: {{ if .Values.global.cluster }}{{ .Values.global.cluster }}{{ else }}{{ .Values.global.region }}{{ end }}
{{- end -}}