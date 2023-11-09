{{- define "nova.console_deployment" }}
{{- $cell_name := index . 1 }}
{{- $type := index . 2 }}
{{- $is_cell2 := index . 3 }}
{{- $config := index . 4 }}
{{- $name := print $cell_name "-" $type }}
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
        {{- tuple . "nova" (print "console-" $name) | include "helm-toolkit.snippets.kubernetes_metadata_labels" | nindent 8 }}
        {{- include "utils.topology.pod_label" . | indent 8 }}
      annotations:
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        {{- if .Values.proxysql.mode }}
        prometheus.io/scrape: "true"
        prometheus.io/targets: {{ required ".Values.alerts.prometheus missing" .Values.alerts.prometheus | quote }}
        {{- end }}
        {{- include "utils.linkerd.pod_and_service_annotation" . | indent 8 }}
    spec:
      {{- tuple . "nova" (print "console-" $name) | include "kubernetes_pod_anti_affinity" | nindent 6 }}
      {{- include "utils.proxysql.pod_settings" . | nindent 6 }}
      {{- tuple . (dict "name" (print "nova-console-" $name )) | include "utils.topology.constraints" | indent 6 }}
      hostname: nova-console-{{ $name }}
      volumes:
      - name: nova-etc
        projected:
          sources:
          - configMap:
              name: nova-etc
              items:
              - key:  nova.conf
                path: nova.conf
              - key:  logging.ini
                path: logging.ini
          {{- if $is_cell2 }}
              - key: nova-cell2.conf
                path: nova.conf.d/cell2.conf
          {{- else }}
          - secret:
              name: nova-etc
              items:
              - key: db.conf
                path: nova.conf.d/db.conf
          {{- end }}
          - configMap:
              name: nova-console
              items:
              - key: console-{{ $cell_name }}-{{ $type }}.conf
                path: nova.conf.d/console-{{ $cell_name }}-{{ $type }}.conf
      {{- include "utils.proxysql.volumes" . | indent 6 }}
      containers:
      - name: nova-console-{{ $type }}
        image: {{ tuple . (print (title $type) "proxy") | include "container_image_nova" }}
        imagePullPolicy: IfNotPresent
        command:
        - dumb-init
        - nova-{{ $type }}proxy
        {{- if $config.args }}
          {{- range (regexSplit "\\s+" $config.args -1) }}
        - {{ . }}
          {{- end }}
        {{- end }}
        env:
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
        - name: {{ $type }}
          containerPort: {{ $config.portInternal }}
        volumeMounts:
        - name: nova-etc
          mountPath: /etc/nova
        {{- include "utils.proxysql.volume_mount" . | indent 8 }}
      {{- include "utils.proxysql.container" . | indent 6 }}
{{- end }}
{{- end }}
