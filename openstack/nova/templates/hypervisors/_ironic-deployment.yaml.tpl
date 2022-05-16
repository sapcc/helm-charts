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
        prometheus.io/port: "9102"
        prometheus.io/targets: {{ required ".Values.alerts.prometheus missing" .Values.alerts.prometheus | quote }}
        {{- end }}
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-ironic-etc-hash: {{ tuple . $hypervisor | include "ironic_configmap" | sha256sum }}
    spec:
      terminationGracePeriodSeconds: {{ $hypervisor.default.graceful_shutdown_timeout | default .Values.defaults.default.graceful_shutdown_timeout | add 5 }}
      containers:
        - name: nova-compute
          image: {{ required ".Values.global.registry is missing" .Values.global.registry}}/ubuntu-source-nova-compute:{{.Values.imageVersionNovaCompute | default .Values.imageVersionNova | default .Values.imageVersion | required "Please set nova.imageVersion or similar" }}
          imagePullPolicy: IfNotPresent
          command:
            - dumb-init
            - kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "nova-compute"
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
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
            - name: PGAPPNAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          {{- if .Values.pod.resources.hv_ironic }}
          resources:
{{ toYaml .Values.pod.resources.hv_ironic | indent 12 }}
          {{- end }}
          volumeMounts:
            - mountPath: /etc/nova
              name: etcnova
            - mountPath: /etc/nova/nova.conf
              name: nova-etc
              subPath: nova.conf
              readOnly: true
            - mountPath: /etc/nova/policy.json
              name: nova-etc
              subPath: policy.json
              readOnly: true
            - mountPath: /etc/nova/logging.ini
              name: nova-etc
              subPath: logging.ini
              readOnly: true
            - mountPath: /etc/nova/nova-compute.conf
              name: hypervisor-config
              subPath: nova-compute.conf
              readOnly: true
            - mountPath: /nova-patches
              name: nova-patches
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
            - name: nova-etc
              mountPath: /etc/statsd/statsd-exporter.yaml
              subPath: statsd-exporter.yaml
              readOnly: true
        {{- end }}
      volumes:
        - name: etcnova
          emptyDir: {}
        - name: nova-etc
          configMap:
            name: nova-etc
        - name: nova-patches
          configMap:
            name: nova-patches
        - name: hypervisor-config
          configMap:
            name: nova-compute-{{$hypervisor.name}}
{{- end -}}
{{- end -}}
