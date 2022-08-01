{{- define "nova.console_deployment" }}
{{- $name := index . 1 }}
{{- $config := index . 2 }}
{{- with index . 0 }}
kind: Deployment
apiVersion: apps/v1

metadata:
  name: nova-console-{{ $name }}
  labels:
    system: openstack
    type: backend
    component: nova
spec:
  replicas: {{ .Values.pod.replicas.console }}
  revisionHistoryLimit: {{ .Values.pod.lifecycle.upgrades.deployments.revision_history }}
  strategy:
    type: {{ .Values.pod.lifecycle.upgrades.deployments.podReplacementStrategy }}
    {{ if eq .Values.pod.lifecycle.upgrades.deployments.podReplacementStrategy "RollingUpdate" }}
    rollingUpdate:
      maxUnavailable: {{ .Values.pod.lifecycle.upgrades.deployments.rollingUpdate.maxUnavailable }}
      maxSurge: {{ .Values.pod.lifecycle.upgrades.deployments.rollingUpdate.maxSurge }}
    {{ end }}
  selector:
    matchLabels:
      name: nova-console-{{ $name }}
  template:
    metadata:
      labels:
        name: nova-console-{{ $name }}
{{ tuple . "nova" (print "console-" $name) | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        {{- if .Values.proxysql.mode }}
        prometheus.io/scrape: "true"
        prometheus.io/targets: {{ required ".Values.alerts.prometheus missing" .Values.alerts.prometheus | quote }}
        {{- end }}
    spec:
{{ tuple . "nova" (print "console-" $name) | include "kubernetes_pod_anti_affinity" | indent 6 }}
{{ include "utils.proxysql.pod_settings" . | indent 6 }}
      hostname: nova-console-{{ $name }}
      volumes:
      - name: etcnova
        emptyDir: {}
      - name: nova-etc
        configMap:
          name: nova-etc
      {{- include "utils.proxysql.volumes" . | indent 6 }}
      containers:
      - name: nova-console-{{ $name }}
        image: {{ required ".Values.global.registry is missing" .Values.global.registry}}/ubuntu-source-nova-{{ $name }}proxy:{{index .Values (print "imageVersionNova" (title $name) "proxy") | default .Values.imageVersionNova | default .Values.imageVersion | required "Please set nova.imageVersion or similar" }}
        imagePullPolicy: IfNotPresent
        command:
        - dumb-init
        - kubernetes-entrypoint
        env:
        - name: COMMAND
          value: nova-{{ $name }}proxy {{ $config.args }}
        - name: NAMESPACE
          value: {{ .Release.Namespace }}
        - name: LANG
          value: en_US.UTF-8
{{- if .Values.python_warnings }}
        - name: PYTHONWARNINGS
          value: {{ .Values.python_warnings | quote }}
{{- end }}
{{- if $config.inject_nova_credentials }}
        - name: OS_USERNAME
          value: {{ .Values.global.nova_service_user | default "nova" }}
        - name: OS_PASSWORD
          value: {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password }}
        - name: OS_PROJECT_NAME
          value: {{.Values.global.keystone_service_project | default "service" }}
        - name: OS_AUTH_URL
          value: {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
{{- end }}
        ports:
        - name: {{ $name }}
          containerPort: {{ index .Values.consoles $name "portInternal" }}
        volumeMounts:
        - name: etcnova
          mountPath: /etc/nova
        - name: nova-etc
          mountPath: /etc/nova/nova.conf
          subPath: nova.conf
          readOnly: true
        - name: nova-etc
          mountPath: /etc/nova/logging.ini
          subPath: logging.ini
          readOnly: true
        {{- include "utils.proxysql.volume_mount" . | indent 8 }}
      {{- include "utils.proxysql.container" . | indent 6 }}
{{- end }}
{{- end }}
