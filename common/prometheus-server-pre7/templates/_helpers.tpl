{{/* Name of the Prometheus. */}}
{{- define "prometheus.name" -}}
{{- required ".Values.name missing" .Values.name -}}
{{- end -}}

{{/* Fullname of the Prometheus. */}}
{{- define "prometheus.fullName" -}}
prometheus-{{- (include "prometheus.name" .) -}}
{{- end -}}

{{/* External URL of this Prometheus. */}}
{{- define "prometheus.externalURL" -}}
{{- if and .Values.ingress.hosts .Values.ingress.hostsFQDN -}}
{{- fail ".Values.ingress.hosts and .Values.ingress.hostsFQDN are mutually exclusive." -}}
{{- end -}}
{{- if .Values.ingress.hosts -}}
{{- $firstHost := first .Values.ingress.hosts -}}
{{- required ".Values.ingress.hosts must have at least one hostname set" $firstHost -}}.{{- required ".Values.global.region missing" .Values.global.region -}}.{{- required ".Values.global.domain missing" .Values.global.domain -}}
{{- else -}}
{{- $firstHost := first .Values.ingress.hostsFQDN -}}
{{- required ".Values.ingress.hostsFQDN must have at least one hostname set" $firstHost -}}
{{- end -}}
{{- end -}}

{{- define "fqdnHelper" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- $host -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.domain missing" $root.Values.global.domain -}}
{{- end -}}

{{/* Prometheus image. */}}
{{- define "prometheus.image" -}}
{{- required ".Values.image.repository missing" .Values.image.repository -}}:{{- required ".Chart.appVersion missing" .Chart.AppVersion -}}
{{- end -}}

{{/* Name of the PVC. */}}
{{- define "pvc.name" -}}
{{- default .Values.name .Values.persistence.name | quote -}}
{{- end -}}

{{/* The name of the serviceAccount. */}}
{{- define "serviceAccount.name" -}}
{{- $name := .Values.serviceAccount.name -}}
{{- if .Values.serviceAccount.create -}}
{{- if and $name (ne $name "default") -}}
{{- $name -}}
{{- else -}}
{{- (include "prometheus.fullName" . ) -}}
{{- end -}}
{{- else -}}
{{- default "default" $name -}}
{{- end -}}
{{- end -}}

{{- define "prometheus-server-pre7.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}

{{- define "prometheus-server-pre7.image.digest" -}}
{{- $parts := splitList "@" (toString .) -}}
{{- if gt (len $parts) 1 -}}
{{- index $parts 1 -}}
{{- end -}}
{{- end -}}

{{/* Keep the operator's semantic version separate from the complete image pin. */}}
{{- define "prometheus-server-pre7.thanos.spec" -}}
{{- $spec := deepCopy .Values.thanos.spec -}}
{{- with $spec.version -}}
{{- $pin := . -}}
{{- $tag := include "prometheus-server-pre7.image.tag" $pin -}}
{{- $digest := include "prometheus-server-pre7.image.digest" $pin -}}
{{- if $digest -}}
{{- $repository := required ".Values.thanos.spec.baseImage missing" $spec.baseImage -}}
{{- $image := default "" $spec.image -}}
{{- $plainImage := include "prometheus-server-pre7.image.tag" $image -}}
{{- $imageDigest := include "prometheus-server-pre7.image.digest" $image -}}
{{- $imageTag := regexFind ":[^/:]+$" $plainImage | trimPrefix ":" -}}
{{- if and $imageDigest (or (ne $imageDigest $digest) (and $imageTag (ne $imageTag $tag))) -}}
{{- fail "thanos.spec.image pin conflicts with thanos.spec.version tag or digest" -}}
{{- end -}}
{{- $_ := set $spec "version" $tag -}}
{{- $_ := set $spec "image" (printf "%s:%s" $repository $pin) -}}
{{- end -}}
{{- end -}}
{{- toYaml $spec -}}
{{- end -}}

{{/* Image for Thanos components. Do not use for Thanos sidecar! */}}
{{- define "thanos.image" -}}
{{- if and .Values.thanos.components.baseImage .Values.thanos.components.version -}}
{{- .Values.thanos.components.baseImage -}}:{{- .Values.thanos.components.version -}}
{{- else -}}
{{- $repository := required ".Values.thanos.spec.baseImage missing" .Values.thanos.spec.baseImage -}}
{{- $pin := required ".Values.thanos.spec.version missing" .Values.thanos.spec.version -}}
{{- if include "prometheus-server-pre7.image.digest" $pin -}}
{{- $spec := include "prometheus-server-pre7.thanos.spec" . | fromYaml -}}
{{- $spec.image -}}
{{- else -}}
{{- $repository -}}:{{- $pin -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "thanos.objectStorageConfig.name" -}}
{{- if and .Values.thanos.spec.objectStorageConfig -}}
{{- required ".Values.thanos.spec.objectStorageConfig.name missing" .Values.thanos.spec.objectStorageConfig.name -}}
{{- else -}}
{{- include "prometheus.fullName" . -}}-{{- required ".Values.thanos.objectStorageConfig.name missing" .Values.thanos.objectStorageConfig.name -}}
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
{{- if .Values.thanos.swiftStorageConfig.tenantName }}
{{- .Values.thanos.swiftStorageConfig.tenantName | quote -}}
{{- else -}}
{{- required ".Values.thanos.swiftStorageConfig.projectName missing" .Values.thanos.swiftStorageConfig.projectName | quote -}}
{{- end -}}
{{- end -}}

{{- define "thanos.projectDomainName" -}}
{{- if .Values.thanos.swiftStorageConfig.projectDomainName -}}
{{- .Values.thanos.swiftStorageConfig.projectDomainName | quote -}}
{{- else -}}
{{- required ".Values.thanos.swiftStorageConfig.domainName missing" .Values.thanos.swiftStorageConfig.domainName | quote -}}
{{- end -}}
{{- end -}}

{{/* Value for prometheus.io/targets annotation. */}}
{{- define "prometheusTargetsValue" -}}
{{- $value := printf ".*%s.*" (include "prometheus.name" . ) -}}
{{- if .Values.serviceDiscoveries.additionalTargets -}}
{{- $value -}}|.*{{- .Values.serviceDiscoveries.additionalTargets | join ".*|.*" -}}.*
{{- else -}}
{{- $value -}}
{{- end -}}
{{- end -}}

{{- define "alerts.tier" -}}
{{- if and .Values.global .Values.global.tier }}
  {{- .Values.global.tier -}}
{{- else -}}
  {{- required ".Values.alerts.tier missing" .Values.alerts.tier -}}
{{- end -}}
{{- end -}}

{{/* If Thanos is enabled the prefix `thanos_` is added to external labels to avoid overriding existing ones (region, cluster) which were added by previous Prometheis in the federation hierarchy. */}}
{{- define "thanosPrefix" -}}
{{- if .Values.thanos.enabled -}}
{{- "thanos_" -}}
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
