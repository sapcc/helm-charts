{{- define "volume_deployment" }}
{{- $name := index . 1 }}
{{- $volume := index . 2 }}
{{- with index . 0 -}}
kind: Deployment
apiVersion: apps/v1
metadata:
  name: {{ .Release.Name }}-volume-{{ $name }}
  labels:
    system: openstack
    type: backend
    component: cinder
spec:
  replicas: 1
  revisionHistoryLimit: {{ .Values.pod.lifecycle.upgrades.deployments.revisionHistory }}
  strategy:
    type: {{ .Values.pod.lifecycle.upgrades.deployments.podReplacementStrategy }}
    {{ if eq .Values.pod.lifecycle.upgrades.deployments.podReplacementStrategy "RollingUpdate" }}
    rollingUpdate:
      maxUnavailable: {{ .Values.pod.lifecycle.upgrades.deployments.rollingUpdate.maxUnavailable }}
      maxSurge: {{ .Values.pod.lifecycle.upgrades.deployments.rollingUpdate.maxSurge }}
    {{ end }}
  selector:
    matchLabels:
        name: {{ .Release.Name }}-volume-{{ $name }}
  template:
    metadata:
      labels:
        name: {{ .Release.Name }}-volume-{{ $name }}
{{ tuple . "cinder" (print "volume-" $name) | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-volume-hash: {{ tuple . $name $volume | include "volume_configmap" | sha256sum }}
        secrets-hash: {{ include (print .Template.BasePath "/secrets.yaml") . | sha256sum }}
        {{- if .Values.proxysql.mode }}
        prometheus.io/scrape: "true"
        prometheus.io/targets: {{ required ".Values.alerts.prometheus missing" .Values.alerts.prometheus | quote }}
        {{- end }}
    spec:
      hostname: {{ .Release.Name }}-volume-{{ $name }}
{{ include "utils.proxysql.pod_settings" . | indent 6 }}
      containers:
      - name: cinder-volume
        image: {{required ".Values.global.registry is missing" .Values.global.registry}}/loci-cinder:{{.Values.imageVersionCinderVolume | default .Values.imageVersion | required "Please set cinder.imageVersion or similar" }}
        imagePullPolicy: IfNotPresent
        command:
        - cinder-volume
        env:
        {{- if .Values.sentry.enabled }}
        - name: SENTRY_DSN
          valueFrom:
            secretKeyRef:
              name: sentry
              key: {{ .Chart.Name }}.DSN.python
        {{- end }}
{{- if or $volume.python_warnings .Values.python_warnings }}
        - name: PYTHONWARNINGS
          value: {{ or $volume.python_warnings .Values.python_warnings | quote }}
{{- end }}
        volumeMounts:
        - name: etccinder
          mountPath: /etc/cinder
        - name: cinder-etc
          mountPath: /etc/cinder/cinder.conf
          subPath: cinder.conf
          readOnly: true
        - name: cinder-etc-confd
          mountPath: /etc/cinder/cinder.conf.d
        - name: cinder-etc
          mountPath: /etc/cinder/policy.json
          subPath: policy.json
          readOnly: true
        - name: cinder-etc
          mountPath: /etc/cinder/logging.ini
          subPath: logging.ini
          readOnly: true
        - name: volume-config
          mountPath: /etc/cinder/nfs_shares
          subPath: nfs_shares
          readOnly: true
        - name: volume-config
          mountPath: /etc/cinder/cinder-volume.conf
          subPath: cinder-volume.conf
          readOnly: true
        - name: cinder-etc
          mountPath: /etc/sudoers
          subPath: sudoers
          readOnly: true
        {{- range $_, $share := $volume.nfs_shares }}
        - name: share-{{ $share.name | required "Please set name to `printf '{host}:{path}' | md5sum`" }}
          mountPath: /var/lib/cinder/mnt/{{ $share.name }}
        {{- end }}
        {{- include "utils.coordination.volume_mount" . | indent 8 }}
        {{- include "utils.proxysql.volume_mount" . | indent 8 }}
      {{- include "utils.proxysql.container" . | indent 6 }}
      {{- include "jaeger_agent_sidecar" . | indent 6 }}
      volumes:
      - name: etccinder
        emptyDir: {}
      - name: cinder-etc
        configMap:
          name: cinder-etc
      - name: cinder-etc-confd
        projected:
          sources:
          - secret:
              name: {{ .Release.Name }}-secrets
              items:
                - key: secrets.conf
                  path: secrets.conf
          - secret:
              name: {{ .Release.Name }}-volume-{{ $name }}-secret
              items:
                - key: cinder-volume-secrets.conf
                  path: cinder-volume-secrets.conf
      - name: volume-config
        configMap:
          name: {{ .Release.Name }}-volume-{{ $name }}
      {{- range $_, $share := $volume.nfs_shares }}
      - name: share-{{ $share.name }}
        nfs:
          path: {{ $share.path | quote }}
          server: {{ $share.host | quote }}
      {{- end }}
      {{- include "utils.coordination.volumes" . | indent 6 }}
      {{- include "utils.proxysql.volumes" . | indent 6 }}
{{- end }}
{{- end }}
