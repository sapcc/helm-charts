{{- define "swift_endpoint_host" -}}
{{- $cluster := index . 0 -}}
{{- $context := index . 1 -}}
{{$cluster.endpoint_host}}.{{$context.global.region}}.{{$context.global.tld}}
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
{{- define "swift_daemonset_annotations" }}
scheduler.alpha.kubernetes.io/tolerations: '[{"key":"species","value":{{ .Values.species | quote }}}]'
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_daemonset_tolerations" }}
{{- if ge .Capabilities.KubeVersion.Minor "7" }}
tolerations:
- key: "species"
  operator: "Equal"
  value: {{ .Values.species | quote}}
  effect: "NoSchedule"
{{- end }}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_prometheus_annotations" }}
prometheus.io/scrape: "true"
prometheus.io/port: "9102"
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_conf_annotations" }}
checksum/swift.etc: {{ include "swift/templates/etc/configmap.yaml" . | sha256sum }}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_ring_annotations" }}
checksum/account.ring: {{ include "swift/templates/account-ring.yaml" . | sha256sum }}
checksum/container.ring: {{ include "swift/templates/container-ring.yaml" . | sha256sum }}
checksum/object.ring: {{ include "swift/templates/object-ring.yaml" . | sha256sum }}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_daemonset_volumes" }}
- name: swift-etc
  configMap:
    name: swift-etc
- name: swift-account-ring
  configMap:
    name: swift-account-ring
- name: swift-container-ring
  configMap:
    name: swift-container-ring
- name: swift-object-ring
  configMap:
    name: swift-object-ring
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
{{- define "swift_standard_container" -}}
{{- $image   := index . 0 -}}
{{- $service := index . 1 -}}
{{- $context := index . 2 }}
- name: {{ $service }}
  image: {{ include "swift_image" $context }}
  command:
    - /usr/bin/dumb-init
  args:
    - /bin/bash
    - /usr/bin/swift-start
    - {{ $service }}
  # privileged access required for /usr/bin/unmount-helper (TODO: use shared/slave mount namespace instead)
  securityContext:
    privileged: true
  env:
    - name: DEBUG_CONTAINER
      value: "false"
  volumeMounts:
    - mountPath: /swift-etc
      name: swift-etc
    - mountPath: /swift-rings/account
      name: swift-account-ring
    - mountPath: /swift-rings/container
      name: swift-container-ring
    - mountPath: /swift-rings/object
      name: swift-object-ring
    - mountPath: /srv/node
      name: swift-drives
    - mountPath: /var/cache/swift
      name: swift-cache
    - mountPath: /swift-drive-state
      name: swift-drive-state
{{- end -}}

{{- /**********************************************************************************/ -}}
When passed via `helm upgrade --set`, the image_version is misinterpreted as a float64. So special care is needed to render it correctly.
{{- define "swift_image" -}}
  {{- if ne .Values.image_version "DEFINED_BY_PIPELINE" -}}
    {{ .Values.global.imageRegistry }}/{{ .Values.imageRegistry_org }}/{{ .Values.imageRegistry_repo }}:{{ .Values.image_version }}
  {{- else -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- end -}}
{{- end }}

{{- define "swift_release" -}}
{{- if ne .image_version "DEFINED_BY_PIPELINE" -}}
    {{ $v := .image_version | split "-"}}{{ $v._0 | lower }}
  {{- end -}}
{{- end }}

{{- /**********************************************************************************/ -}}
{{- define "swift_statsd_exporter_container" }}
- name: statsd
  image: prom/statsd-exporter:{{.Values.image_version_auxiliary_statsd_exporter}}
  args: [ -statsd.mapping-config=/swift-etc/statsd-exporter.yaml ]
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
