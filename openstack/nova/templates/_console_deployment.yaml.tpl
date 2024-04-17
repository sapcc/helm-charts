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
  {{- if .Values.vpa.set_main_container }}
  annotations:
    vpa-butler.cloud.sap/main-container: nova-console-{{ $type }}
  {{- end }}
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
          - secret:
              name: nova-etc
              items:
              - key: api-db.conf
                path: nova.conf.d/api-db.conf
              - key: {{ $cell_name }}.conf
                path: nova.conf.d/{{ $cell_name }}.conf
          - configMap:
              name: nova-console
              items:
              - key: console-{{ $cell_name }}-{{ $type }}.conf
                path: nova.conf.d/console-{{ $cell_name }}-{{ $type }}.conf
      {{- include "utils.proxysql.volumes" . | indent 6 }}
      {{- include "utils.trust_bundle.volumes" . | indent 6 }}
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
        ports:
        - name: {{ $type }}
          containerPort: {{ $config.portInternal }}
        volumeMounts:
        - name: nova-etc
          mountPath: /etc/nova
        {{- include "utils.proxysql.volume_mount" . | indent 8 }}
        {{- include "utils.trust_bundle.volume_mount" . | indent 8 }}
      {{- include "utils.proxysql.container" . | indent 6 }}
{{- end }}
{{- end }}
