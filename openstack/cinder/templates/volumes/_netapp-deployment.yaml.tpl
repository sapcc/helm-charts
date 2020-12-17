{{- define "volume_netapp" -}}
{{- $volume := index . 1 -}}
{{- with index . 0 -}}
kind: Deployment
apiVersion: apps/v1
metadata:
  name: cinder-volume-netapp-{{$volume.name}}
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
        name: cinder-volume-netapp-{{$volume.name}}
  template:
    metadata:
      labels:
        name: cinder-volume-netapp-{{$volume.name}}
{{ tuple . "cinder" (print "volume-netapp-" $volume.name) | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        pod.beta.kubernetes.io/hostname: cinder-volume-netapp-{{$volume.name}}
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-volume-hash: {{ tuple . $volume | include "volume_netapp_configmap" | sha256sum }}
    spec:
      hostname: cinder-volume-netapp-{{$volume.name}}
      containers:
      - name: cinder-volume-netapp-{{$volume.name}}
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
          value: {{ or $volume.python_warnings .Values.python_warnings }}
{{- end }}
        volumeMounts:
        - name: cinder-etc
          mountPath: /etc/cinder
      volumes:
      - name: cinder-etc
        projected:
          defaultMode: 420
          sources:
          - configMap:
              items:
              - key: cinder.conf
                path: cinder.conf
              - key: policy.json
                path: policy.json
              - key: logging.ini
                path: logging.ini
              name: cinder-etc
          - configMap
              items:
              - key: cinder-volume.conf
                path: cinder-volume.conf
              name: volume-netapp-{{$volume.name}}
{{- end -}}
{{- end -}}
