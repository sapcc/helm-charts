{{- define "volume_deployment" -}}
{{- $volume := index . 1 -}}
{{- with index . 0 -}}
kind: Deployment
apiVersion: apps/v1
metadata:
  name: cinder-volume-{{$volume.name}}
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
        name: cinder-{{$volume.name}}
  template:
    metadata:
      labels:
        name: cinder-{{$volume.name}}
{{ tuple . "cinder" (print "volume-" $volume.name) | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-volume-hash: {{ tuple . $volume | include "volume_configmap" | sha256sum }}
        {{- if .Values.proxysql.mode }}
        prometheus.io/scrape: "true"
        prometheus.io/targets: {{ required ".Values.alerts.prometheus missing" .Values.alerts.prometheus | quote }}
        {{- end }}
    spec:
      hostname: cinder-volume-{{$volume.name}}
{{ include "utils.proxysql.pod_settings" . | indent 6 }}
      containers:
      - name: cinder-volume-{{$volume.name}}
        image: {{required ".Values.global.registry is missing" .Values.global.registry}}/loci-cinder:{{.Values.imageVersionCinderVolume | default .Values.imageVersion | required "Please set cinder.imageVersion or similar" }}
        imagePullPolicy: IfNotPresent
        command:
        - kubernetes-entrypoint
        env:
        - name: COMMAND
          value: "cinder-volume"
        - name: NAMESPACE
          value: {{ .Release.Namespace }}
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
        - name: cinder-etc
          mountPath: /etc/cinder/policy.json
          subPath: policy.json
          readOnly: true
        - name: cinder-etc
          mountPath: /etc/cinder/logging.ini
          subPath: logging.ini
          readOnly: true
        - name: volume-config
          mountPath: /etc/cinder/cinder-volume.conf
          subPath: cinder-volume.conf
          readOnly: true
        - name: cinder-etc
          mountPath: /etc/sudoers
          subPath: sudoers
          readOnly: true
        {{- include "utils.proxysql.volume_mount" . | indent 10 }}
      {{- include "utils.proxysql.container" . | indent 8 }}
      volumes:
      - name: etccinder
        emptyDir: {}
      - name: cinder-etc
        configMap:
          name: cinder-etc
      - name: volume-config
        configMap:
          name:  volume-{{$volume.name}}
      {{- include "utils.proxysql.volumes" . | indent 8 }}
{{- end -}}
{{- end -}}
