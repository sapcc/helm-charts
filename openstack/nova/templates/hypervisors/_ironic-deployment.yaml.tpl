{{- define "ironic_deployment" -}}
{{- $hypervisor := index . 1 -}}
{{- with index . 0 -}}
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nova-compute-{{$hypervisor.name}}
  labels:
    system: openstack
    type: backend
    component: nova
  {{- if .Values.vpa.set_main_container }}
  annotations:
    vpa-butler.cloud.sap/main-container: nova-compute
  {{- end }}
spec:
  replicas: 1
  revisionHistoryLimit: {{ .Values.pod.lifecycle.upgrades.deployments.revision_history }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 3
  selector:
    matchLabels:
      name: nova-compute-{{$hypervisor.name}}
  template:
    metadata:
      labels:
{{ tuple . "nova" "compute" | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
        name: nova-compute-{{$hypervisor.name}}
        alert-tier: os
        alert-service: nova
        hypervisor: "ironic"
      annotations:
        {{- if $hypervisor.default.statsd_enabled }}
        prometheus.io/scrape: "true"
        prometheus.io/targets: {{ required ".Values.alerts.prometheus missing" .Values.alerts.prometheus | quote }}
        {{- end }}
        {{- include "utils.linkerd.pod_and_service_annotation" . | indent 8 }}
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-ironic-etc-hash: {{ tuple . $hypervisor | include "ironic_configmap" | sha256sum }}
    spec:
      terminationGracePeriodSeconds: {{ $hypervisor.default.graceful_shutdown_timeout | default .Values.defaults.default.graceful_shutdown_timeout | add 5 }}
      initContainers:
      {{- tuple . (dict "service" (print .Release.Name "-rabbitmq")) | include "utils.snippets.kubernetes_entrypoint_init_container" | indent 6 }}
      containers:
        - name: nova-compute
          image: {{ tuple . "compute" | include "container_image_nova" }}
          imagePullPolicy: IfNotPresent
          command: ["dumb-init", "nova-compute"]
          env:
          {{- if .Values.sentry.enabled }}
          - name: SENTRY_DSN
            valueFrom:
              secretKeyRef:
                name: sentry
                key: {{ .Chart.Name }}.DSN.python
          {{- end }}
{{- if or $hypervisor.python_warnings .Values.python_warnings }}
          - name: PYTHONWARNINGS
            value: {{ or $hypervisor.python_warnings .Values.python_warnings | quote }}
{{- end }}
          {{- if .Values.pod.resources.hv_ironic }}
          resources:
{{ toYaml .Values.pod.resources.hv_ironic | indent 12 }}
          {{- end }}
          volumeMounts:
            - mountPath: /etc/nova
              name: nova-etc
            - mountPath: /nova-patches
              name: nova-patches
            {{- include "utils.trust_bundle.volume_mount" . | indent 12 }}
        {{- if $hypervisor.default.statsd_enabled }}
        - name: statsd
          image: {{ required ".Values.global.dockerHubMirror is missing" .Values.global.dockerHubMirror}}/prom/statsd-exporter:v0.8.1
          imagePullPolicy: IfNotPresent
          args: [ --statsd.mapping-config=/etc/statsd/statsd-exporter.yaml ]
          ports:
          - name: statsd
            containerPort: {{ $hypervisor.default.statsd_port }}
            protocol: UDP
          - name: metrics
            containerPort: 9102
          volumeMounts:
          - name: statsd-etc
            mountPath: /etc/statsd/statsd-exporter.yaml
            subPath: statsd-exporter.yaml
            readOnly: true
        {{- end }}
      volumes:
      - name: nova-etc
        projected:
          sources:
          - configMap:
              name: nova-etc
              items:
              - key: nova.conf
                path: nova.conf
              - key: policy.yaml
                path: policy.yaml
              - key: logging.ini
                path: logging.ini
          - configMap:
              name: nova-compute-{{$hypervisor.name}}
              items:
              - key: nova-compute.conf
                path: nova-compute.conf
          - configMap:
              name: nova-console
              items:
              {{- range $type := list "serial" "shellinabox" }}
              - key: console-cell1-{{ $type }}.conf
                path: nova.conf.d/console-cell1-{{ $type }}.conf
              {{- end }}
          - secret:
              name: nova-etc
              items:
              - key: cell1.conf
                path: nova.conf.d/cell1-secrets.conf
              - key: keystoneauth-secrets.conf
                path: nova.conf.d/keystoneauth-secrets.conf
      - name: nova-patches
        projected:
          sources:
          - configMap:
              name: nova-patches
      {{- if $hypervisor.default.statsd_enabled }}
      - name: statsd-etc
        projected:
          sources:
          - configMap:
              name: nova-etc
              items:
              - key:  statsd-exporter.yaml
                path: statsd-exporter.yaml
      {{- end }}
      {{- include "utils.trust_bundle.volumes" . | indent 6 }}
{{- end -}}
{{- end -}}
