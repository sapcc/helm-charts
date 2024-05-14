{{/* Name of the Prometheus. */}}
{{- define "prometheus.name" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if and (not $root.Values.names) (not $root.Values.global.targets) (not $root.Values.name) -}}
{{- fail "Cannot create any Prometheus resource. Please define a name or at least one list element to names or global.targets" -}}
{{- end -}}
{{/* vmware prometheis need additional renaming */}}
{{- if or $root.Values.vmware $root.Values.thanosSeeds.vmware -}}
{{- include "vmwareRenaming" $name -}}
{{- else -}}
{{- $name -}}
{{- end -}}
{{- end -}}

{{/* Fullname of the Prometheus. */}}
{{- define "prometheus.fullName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{/* vmware prometheis need additional renaming */}}
{{- if $root.Values.vmware -}}
prometheus-{{- include "vmwareRenaming" $name -}}
{{- else -}}
prometheus-{{- (include "prometheus.name" .) -}}
{{- end -}}
{{- end -}}

{{/* External URL of this Prometheus. */}}
{{- define "prometheus.externalURL" -}}
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
{{/* vmware prometheis need additional renaming */}}
{{- else if $root.Values.vmware -}}
prometheus-{{- include "vmwareRenaming" $name -}}.{{- required "$root.Values.global.region missing" $root.Values.global.region -}}.{{- required "$root.Values.global.tld missing" $root.Values.global.tld -}}
{{- else -}}
prometheus-{{- $name -}}.{{- required "$root.Values.global.region missing" $root.Values.global.region -}}.{{- required "$root.Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{- define "fqdnHelper" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- if not $root.Values.ingress.hosts -}}
{{- (include "prometheus.fullName" .) -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- else -}}
{{- $host -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{- define "internalFQDNHelper" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- if not $root.Values.internalIngress.hosts -}}
{{- (include "prometheus.fullName" .) -}}-internal.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- else -}}
{{- $host -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.tld missing" $root.Values.global.tld -}}
{{- end -}}
{{- end -}}

{{/* Prometheus image. */}}
{{- define "prometheus.image" -}}
{{- required ".Values.image.repository missing" .Values.image.repository -}}:{{- required ".Chart.appVersion missing" .Chart.AppVersion -}}
{{- end -}}

{{/* Name of the PVC. */}}
{{- define "pvc.name" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{/* vmware prometheis need additional renaming */}}
{{- if $root.Values.vmware -}}
{{- include "vmwareRenaming" $name -}}
{{- else -}}
{{- default $name $root.Values.persistence.name | quote -}}
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
{{- (include "prometheus.fullName" . ) -}}
{{- end -}}
{{- else -}}
{{- default "default" $svcName -}}
{{- end -}}
{{- end -}}

{{/* Image for Thanos components. Do not use for Thanos sidecar! */}}
{{- define "thanos.image" -}}
{{- if and .Values.thanos.components.baseImage .Values.thanos.components.version -}}
{{- .Values.thanos.components.baseImage -}}:{{- .Values.thanos.components.version -}}
{{- else -}}
{{- required ".Values.thanos.spec.baseImage missing" .Values.thanos.spec.baseImage -}}:{{- required ".Values.thanos.spec.version missing" .Values.thanos.spec.version -}}
{{- end -}}
{{- end -}}

{{- define "thanos.objectStorageConfig.name" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if and $root.Values.thanos.spec.objectStorageConfig -}}
{{- required ".Values.thanos.spec.objectStorageConfig.name missing" $root.Values.thanos.spec.objectStorageConfig.name -}}
{{- else -}}
{{- include "prometheus.fullName" . -}}-{{- required ".Values.thanos.objectStorageConfig.name missing" $root.Values.thanos.objectStorageConfig.name -}}
{{- end -}}
{{- end -}}

{{- define "thanos.objectStorageConfig.key" -}}
{{- if .Values.thanos.spec.objectStorageConfig -}}
{{- required ".Values.thanos.spec.objectStorageConfig.key missing" .Values.thanos.spec.objectStorageConfig.key -}}
{{- else -}}
{{- required ".Values.thanos.objectStorageConfig.key missing" .Values.thanos.objectStorageConfig.key -}}
{{- end -}}
{{- end -}}

{{- define "thanos.projectName" -}}
{{- if .Values.thanosSeeds.swiftStorageConfig.tenantName }}
{{- .Values.thanosSeeds.swiftStorageConfig.tenantName | quote -}}
{{- else -}}
{{- required ".Values.thanosSeeds.swiftStorageConfig.projectName missing" .Values.thanosSeeds.swiftStorageConfig.projectName | quote -}}
{{- end -}}
{{- end -}}

{{- define "thanos.projectDomainName" -}}
{{- if .Values.thanosSeeds.swiftStorageConfig.projectDomainName -}}
{{- .Values.thanosSeeds.swiftStorageConfig.projectDomainName | quote -}}
{{- else -}}
{{- required ".Values.thanosSeeds.swiftStorageConfig.domainName missing" .Values.thanosSeeds.swiftStorageConfig.domainName | quote -}}
{{- end -}}
{{- end -}}

{{/* Value for prometheus.io/targets annotation. */}}
{{- define "prometheusTargetsValue" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if $root.Values.vmware -}}
{{- include "vmwareRenaming" $name -}}
{{- else -}}
{{- $value := printf ".*%s.*" $name -}}
{{- if $root.Values.serviceDiscoveries.additionalTargets -}}
{{- $value -}}|.*{{- $root.Values.serviceDiscoveries.additionalTargets | join ".*|.*" -}}.*
{{- else -}}
{{- $value -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "alerts.tier" -}}
{{- if and .Values.global .Values.global.tier }}
  {{- .Values.global.tier -}}
{{- else -}}
  {{- required ".Values.alerts.tier missing" .Values.alerts.tier -}}
{{- end -}}
{{- end -}}

{{- define "prometheus.defaultRelabelConfig" -}}
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

{{- define "prometheus.keep-metrics.metric-relabel-config" -}}
- sourceLabels: [ __name__ ]
  regex: ^({{ . | join "|" }})$
  action: keep
{{- end -}}

{{- define "prometheus.drop-metrics.metric-relabel-config" -}}
- sourceLabels: [ __name__ ]
  regex: ^({{ . | join "|" }})$
  action: drop
{{- end -}}

{{/* Generated Swift userName*/}}
{{- define "swift.userName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if $root.Values.thanosSeeds.swiftStorageConfig.userName -}}
{{- $root.Values.thanosSeeds.swiftStorageConfig.userName -}}
{{- else if $root.Values.thanosSeeds.seed.clusterType -}}
{{- (include "prometheus.fullName" .) -}}-{{- $root.Values.thanosSeeds.seed.clusterType -}}-thanos
{{- else -}}
{{- (include "prometheus.fullName" .) -}}-thanos
{{- end -}}
{{- end -}}

{{/* Generated Swift containerName*/}}
{{- define "swift.containerName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if $root.Values.thanosSeeds.swiftStorageConfig.containerName -}}
{{- $root.Values.thanosSeeds.swiftStorageConfig.containerName -}}
{{- else if $root.Values.thanosSeeds.seed.clusterType -}}
{{- (include "prometheus.fullName" .) -}}-{{- $root.Values.thanosSeeds.seed.clusterType -}}-thanos
{{- else -}}
{{- (include "prometheus.fullName" .) -}}-thanos
{{- end -}}
{{- end -}}

{{/* Special renaming for vmware-monitoring */}}
{{- define "vmwareRenaming" -}}
{{- $vropshostname := split "." . -}}
vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}
