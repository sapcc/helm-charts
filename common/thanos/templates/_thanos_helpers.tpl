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
{{- include "vmwareRenaming" $name -}}
{{- else -}}
{{- $name -}}
{{- end -}}
{{- end -}}

{{/* Thanos combined name */}}
{{- define "thanos.fullName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if $root.Values.vmware -}}
thanos-{{- include "vmwareRenaming" $name -}}
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
{{- required ".Values.ingress.hosts must have at least one hostname set" $firstHost -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- else if $root.Values.ingress.hostsFQDN -}}
{{- $firstHost := first $root.Values.ingress.hostsFQDN -}}
{{- required ".Values.ingress.hostsFQDN must have at least one hostname set" $firstHost -}}
{{- else -}}
thanos-{{ $name }}.{{- required "$root.Values.global.region missing" $root.Values.global.region -}}.{{- required "$root.Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{/* External gRPC URL of this Thanos. */}}
{{- define "thanos.grpcURL" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if $root.Values.grpcIngress.hosts -}}
{{- $firstHost := first $root.Values.grpcIngress.hosts -}}
{{- required ".Values.grpcIngress.hosts must have at least one hostname set" $firstHost -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- else -}}
thanos-{{ $name }}-grpc.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{/* External URL to expose Thanos API only. */}}
{{- define "thanos.internalURL" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if $root.Values.internalIngress.hosts -}}
{{- $firstHost := first $root.Values.internalIngress.hosts -}}
{{- required ".Values.internalIngress.hosts must have at least one hostname set" $firstHost -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- else -}}
thanos-{{ $name }}-internal.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{- define "fqdnHelper" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- if not $root.Values.ingress.hosts -}}
{{- (include "thanos.fullName" .) -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- else -}}
{{ $host }}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{- define "grpcFqdnHelper" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- if not $root.Values.grpcIngress.hosts -}}
{{- (include "thanos.fullName" .) -}}-grpc.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- else -}}
{{ $host }}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{- define "internalFqdnHelper" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- if not $root.Values.internalIngress.hosts -}}
{{- (include "thanos.fullName" .) -}}-internal.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
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

{{/* Special renaming for vmware-monitoring */}}
{{- define "vmwareRenaming" -}}
{{- $vropshostname := split "." . -}}
vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}

{{- define "clusterDomainOrDefault" }}
{{- if $.Values.clusterDomain }}
{{- $.Values.clusterDomain }}.{{ $.Values.global.region }}.{{ $.Values.global.tld }}
{{- else -}}
cluster.local
{{- end -}}
{{- end -}}

{{/* The name of the serviceAccount. */}}
{{- define "serviceAccount.name" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $svcName := $root.Values.serviceAccount.name -}}
{{- if $root.Values.serviceAccount.create -}}
{{- if and $svcName (ne $svcName "default") -}}
{{- $svcName -}}
{{- else -}}
{{- (include "thanos.fullName" . ) -}}
{{- end -}}
{{- else -}}
{{- default "default" $svcName -}}
{{- end -}}
{{- end -}}

{{- define "thanos.storeAPIs" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{/* Thanos Query discovery within the cluster */}}
{{- if $root.Values.queryDiscovery -}}
- targets:
{{- $clusterList := list }}
{{- range $index, $service := (lookup "v1" "Service" "" "").items }}
{{- if and (hasPrefix "thanos" $service.metadata.name) (contains "query" $service.metadata.name) (not (contains "maia" $service.metadata.name)) (not (contains "metal" $service.metadata.name)) (not (contains "scaleout" $service.metadata.name)) (not (contains "regional" $service.metadata.name)) (not (contains "global" $service.metadata.name)) }}
{{- $store := $service.metadata.name }}
{{- $storeItem := printf "dnssrvnoa+_grpc._tcp.%s.%s.svc.%s" $store $service.metadata.namespace (include "clusterDomainOrDefault" $root) -}}
{{- $clusterList = append $clusterList $storeItem -}}
{{- end }}
{{- end }}
{{- range $clusterList | sortAlpha }}
  - {{ . }}
{{- end }}
{{/* Global Thanos Query Store API endpoints */}}
{{- else if and $root.Values.useQueryRegions $root.Values.queryStoreAPIs -}}
- targets:
{{- $globalList := list }}
{{- range $region := $root.Values.queryRegions -}}
{{- range $cluster := $root.Values.queryStoreAPIs -}}
{{- $storeItem := printf "thanos-%s-grpc.%s.%s" $cluster $region $root.Values.global.tld -}}
{{- $globalList = append $globalList $storeItem -}}
{{- end -}}
{{- end -}}
{{- range $store := $root.Values.query.stores -}}
{{- $storeItem := printf "%s.%s" $store $root.Values.global.tld -}}
{{- $globalList = append $globalList $storeItem -}}
{{- end -}}
{{- range $globalList | sortAlpha }}
  - {{ . }}:443
{{- end }}
{{/* Regional Thanos Query Store API endpoints */}}
{{- else if and (not $root.Values.useQueryRegions) $root.Values.queryStoreAPIs -}}
- targets:
{{- $regionalList := list }}
{{- range $cluster := $root.Values.queryStoreAPIs }}
{{- $storeItem := printf "thanos-%s-grpc.%s.%s" $cluster $root.Values.global.region $root.Values.global.tld -}}
{{- $regionalList = append $regionalList $storeItem -}}
{{- end }}
{{- range $regionalList | sortAlpha }}
  - {{ . }}:443
{{- end }}
{{- end }}
{{- end }}
