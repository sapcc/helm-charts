{{- define "swift_endpoint_host" -}}
{{ .Values.endpoint_host}}.{{ .Values.global.region }}.{{ .Values.global.tld }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $release := index . 0 -}}
{{- $chart := index . 1 -}}
{{- $values := index . 2 -}}
{{- $name := default $chart.Name $values.nameOverride -}}
{{- printf "%s-%s" $release.Name $name | trunc 24 -}}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_daemonset_tolerations" }}
tolerations:
- key: "species"
  operator: "Equal"
  value: "{{ .Values.species }}"
  effect: "NoSchedule"
- key: "species"
  operator: "Equal"
  value: "{{ .Values.species }}-multipath"
  effect: "NoSchedule"
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_prometheus_annotations" }}
prometheus.io/scrape: "true"
prometheus.io/port: "9102"
prometheus.io/targets: {{ required ".Values.alerts.prometheus.openstack missing" .Values.alerts.prometheus.openstack }}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_conf_annotations" }}
checksum/swift.etc: {{ include "swift/templates/etc/configmap.yaml" . | sha256sum }}
checksum/swift.secret: {{ include "swift/templates/secret.yaml" . | sha256sum }}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_daemonset_volumes" }}
- name: swift-etc
  configMap:
    name: swift-etc
- name: swift-rings
  emptyDir: {}
- name: swift-drives
  hostPath:
    path: /srv/node
- name: swift-cache
  hostPath:
    path: /var/cache/swift
- name: swift-drive-state
  hostPath:
    path: /run/swift-storage/state
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_proxy_volumes" }}
- name: swift-etc
  configMap:
    name: swift-etc
- name: swift-etc-cluster
  configMap:
    name: swift-etc-{{ .Values.cluster_name }}
- name: swift-rings
  emptyDir: {}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_proxy_containers" }}
{{- $kind       := index . 0 -}}
{{- $context    := index . 1 }}
- name: proxy
  image: {{ include "swift_image" $context }}
  command:
    - /bin/bash
  args:
    - /usr/bin/swift-start
    - proxy-server
  env:
    - name: DEBUG_CONTAINER
      value: "false"
    - name: HASH_PATH_PREFIX
      valueFrom:
        secretKeyRef:
          name: swift-secret
          key: hash_path_prefix
    - name: HASH_PATH_SUFFIX
      valueFrom:
        secretKeyRef:
          name: swift-secret
          key: hash_path_suffix
    - name: SWIFT_SERVICE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: swift-secret
          key: {{ $context.Values.cluster_name }}_service_password
  {{- $resources_cpu := index $context.Values (printf "proxy_%s_resources_cpu" $kind) }}
  {{- $resources_memory := index $context.Values (printf "proxy_%s_resources_memory" $kind) }}
  resources:
    requests:
      cpu: {{ required (printf "proxy_%s_resources_cpu is required" $kind) $resources_cpu | quote }}
      memory: {{ required (printf "proxy_%s_resources_memory is required" $kind) $resources_memory | quote }}
    limits:
      cpu: {{ required (printf "proxy_%s_resources_cpu is required" $kind) $resources_cpu | quote }}
      memory: {{ required (printf "proxy_%s_resources_memory is required" $kind) $resources_memory | quote }}
  # TODO: securityContext: { runAsNonRoot: true }
  volumeMounts:
    - mountPath: /swift-etc
      name: swift-etc
    - mountPath: /swift-etc-cluster
      name: swift-etc-cluster
    - mountPath: /swift-rings
      name: swift-rings
  livenessProbe:
    httpGet:
      path: /healthcheck
      port: 8080
      scheme: HTTP
    initialDelaySeconds: 10
    timeoutSeconds: 1
    periodSeconds: 10
{{- if $context.Values.health_exporter }}
- name: collector
  image: {{ include "swift_image" $context }}
  command:
    - /bin/bash
  args:
    - /usr/bin/swift-start
    - health-exporter
    - --recon.timeout=20
    - --recon.timeout-host=2
  env:
    - name: HASH_PATH_PREFIX
      valueFrom:
        secretKeyRef:
          name: swift-secret
          key: hash_path_prefix
    - name: HASH_PATH_SUFFIX
      valueFrom:
        secretKeyRef:
          name: swift-secret
          key: hash_path_suffix
    - name: DISPERSION_PASSWORD
      valueFrom:
        secretKeyRef:
          name: swift-secret
          key: dispersion_password
  ports:
    - name: metrics
      containerPort: 9520
  resources:
    # observed usage: CPU = ~10m, RAM = 70-100 MiB
    # low cpu allocation results in performance degradation
    requests:
      cpu: "300m"
      memory: "150Mi"
    limits:
      cpu: "600m"
      memory: "150Mi"
  # TODO: securityContext: { runAsNonRoot: true }
  volumeMounts:
    - mountPath: /swift-etc
      name: swift-etc
    - mountPath: /swift-rings
      name: swift-rings
{{- end}}
- name: statsd
  image: {{ $context.Values.global.dockerHubMirrorAlternateRegion }}/prom/statsd-exporter:{{ $context.Values.image_version_auxiliary_statsd_exporter }}
  args: [ --statsd.mapping-config=/swift-etc/statsd-exporter.yaml ]
  {{- $resources_cpu := index $context.Values "proxy_statsd_exporter_resources_cpu" }}
  {{- $resources_memory := index $context.Values "proxy_statsd_exporter_resources_memory" }}
  securityContext:
    runAsNonRoot: true
  resources:
    requests:
      cpu: {{ required "proxy_statsd_exporter_resources_cpu is required" $resources_cpu | quote }}
      memory: {{ required "proxy_statsd_exporter_resources_memory is required" $resources_memory | quote }}
    limits:
      cpu: {{ required "proxy_statsd_exporter_resources_cpu is required" $resources_cpu | quote }}
      memory: {{ required "proxy_statsd_exporter_resources_memory is required" $resources_memory | quote }}
  ports:
    - name: statsd
      containerPort: 9125
      protocol: UDP
    - name: metrics
      containerPort: 9102
  volumeMounts:
    - mountPath: /swift-etc
      name: swift-etc
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_standard_container" -}}
{{- $image   := index . 0 -}}
{{- $service := index . 1 -}}
{{- $context := index . 2 }}
- name: {{ $service }}
  image: {{ include "swift_image" $context }}
  command:
    - /bin/bash
  args:
    - /usr/bin/swift-start
    - {{ $service }}
  # privileged access required for /usr/bin/unmount-helper (TODO: use shared/slave mount namespace instead)
  securityContext:
    runAsUser: 0
    privileged: true
  env:
    - name: DEBUG_CONTAINER
      value: "false"
    - name: HASH_PATH_PREFIX
      valueFrom:
        secretKeyRef:
          name: swift-secret
          key: hash_path_prefix
    - name: HASH_PATH_SUFFIX
      valueFrom:
        secretKeyRef:
          name: swift-secret
          key: hash_path_suffix
  volumeMounts:
    - mountPath: /swift-etc
      name: swift-etc
    - mountPath: /swift-rings
      name: swift-rings
    - mountPath: /srv/node
      name: swift-drives
    - mountPath: /var/cache/swift
      name: swift-cache
    - mountPath: /swift-drive-state
      name: swift-drive-state
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_ringloader_initcontainer" }}
- name: ringloader
  image: {{ include "swift_rings_image" . }}
  command: [ /bin/sh ]
  args:
    - '-c'
    - |
      set -euo pipefail
      cat < /swift-rings/{{ .Values.global.region }}/account.ring.gz   > /swift-rings-out/account.ring.gz
      cat < /swift-rings/{{ .Values.global.region }}/container.ring.gz > /swift-rings-out/container.ring.gz
      cat < /swift-rings/{{ .Values.global.region }}/object.ring.gz    > /swift-rings-out/object.ring.gz
  # TODO: securityContext: { runAsNonRoot: true }
  volumeMounts:
    - mountPath: /swift-rings-out
      name: swift-rings
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_image" -}}
  {{- if ne .Values.image_version "DEFINED_BY_PIPELINE" -}}
    {{ .Values.global.registryAlternateRegion }}/{{ .Values.imageRegistry_repo }}:{{ .Values.image_version }}
  {{- else -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- end -}}
{{- end }}

{{- /**********************************************************************************/ -}}
{{- define "swift_rings_image" -}}
  {{- if ne .Values.rings_image_version "DEFINED_BY_PIPELINE" -}}
    {{ .Values.global.registryAlternateRegion }}/swift-rings:{{ .Values.rings_image_version }}
  {{- else -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- end -}}
{{- end }}

{{- /**********************************************************************************/ -}}
{{- define "swift_release" -}}
{{- if ne .Values.image_version "DEFINED_BY_PIPELINE" -}}
  {{ $v := .Values.image_version | split "-"}}{{ $v._0 | lower }}
{{- end -}}
{{- end }}

{{- /* Generate backend host for sapcc/openstack-ratelimit-middleware */ -}}
{{- define "sapcc_ratelimit_backend_host" -}}
{{- if .Values.sapcc_ratelimit.backend.host -}}
{{- .Values.sapcc_ratelimit.backend.host -}}
{{- else -}}
{{- .Release.Name -}}-sapcc-ratelimit-redis
{{- end -}}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_log_statsd" -}}
log_statsd_host = localhost
log_statsd_port = 9125
log_statsd_default_sample_rate = 1.0
log_statsd_sample_rate_factor = 1.0
log_statsd_metric_prefix = swift
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_haproxy_backend" -}}
#option http-server-close
{{- if .Values.upstreams }}
balance roundrobin
option httpchk HEAD /healthcheck
default-server check downinter 30s maxconn 500
{{- range $index, $upstream := .Values.upstreams }}
{{- $short_name := splitn "." 2  $upstream.name }}
server {{ printf "%9s" $short_name._0 }} {{ $upstream.target }}:{{ default 8080 $.Values.svc_node_port }} {{ if ne $short_name._0 $upstream.name }}# {{ $upstream.name }}{{ end }}
{{- end }}
{{- else }}
server swift-svc swift-proxy-internal-{{ .Values.cluster_name }}:8080
{{- end }}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- /* Generate a VerticalPodAutoscaler object that ensures that our daemonsets never get automated CPU/memory requests. */ -}}
{{- define "swift_vpa_no_autoupdates" -}}
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: {{ . }}

spec:
  targetRef:
    apiVersion: v1
    kind: DaemonSet
    name: {{ . }}
  resourcePolicy:
    containerPolicies:
    - containerName: '*'
      controlledResources:
      - cpu
      - memory
  updatePolicy:
    updateMode: 'Off'
{{- end -}}
