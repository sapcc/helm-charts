{{- define "keystone.migration_job" -}}
{{- $phase := .phase -}}
{{- $job := .job -}}
{{- with .root }}
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ tuple . $job | include "job_name" }}"
  labels:
    app: {{ template "fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
    system: openstack
    component: keystone
    type: job
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        name: "{{ tuple . $job | include "job_name" }}"
        {{- include "keystone.upgrade_labels" . | nindent 8 }}
        system: openstack
        component: keystone
        type: job
        alert-tier: os
        alert-service: keystone
      annotations:
        chart-version: {{.Chart.Version}}
        configmap-bin-hash: {{ include (print .Template.BasePath "/configmap-bin.yaml") . | sha256sum }}
        configmap-etc-hash: {{ include (print .Template.BasePath "/configmap-etc.yaml") . | sha256sum }}
{{- include "utils.linkerd.pod_and_service_annotation" . | indent 8 }}
    spec:
{{- if .Values.rbac.enabled }}
      serviceAccountName: {{ .Release.Name }}
{{- end }}
      restartPolicy: Never
      {{- include "utils.proxysql.job_pod_settings" . | indent 6 }}
      initContainers:
      {{- $dependencies := dict "SERVICE" (include "keystone.db_service" .) }}
      {{- if eq $phase "contract" }}
        {{- $_ := set $dependencies "JOBS" (include "keystone.job_dependencies" .) }}
      {{- end }}
      {{- tuple . $dependencies | include "keystone.kubernetes_entrypoint_init_container" | indent 6 }}
      {{- if .Values.proxysql.native_sidecar }}
      {{- include "utils.proxysql.container" . | indent 6 }}
      {{- end }}
      containers:
        - name: keystone-migration
          image: {{ required ".Values.global.registryAlternateRegion is missing" .Values.global.registryAlternateRegion }}/{{ .Values.api.image }}:{{ .Values.api.imageTag }}
          imagePullPolicy: {{ default "IfNotPresent" .Values.api.imagePullPolicy | quote }}
          command:
            - bash
            - /upgrade/db-sync
            - {{ $phase }}
          env:
            {{- if eq $phase "contract" }}
            {{- include "keystone.rollout_env" . | nindent 12 }}
            {{- end }}
            {{- if .Values.sentry.enabled }}
            - name: SENTRY_DSN
            {{- if .Values.sentry.dsn }}
              value: {{ .Values.sentry.dsn | quote}}
            {{ else }}
              valueFrom:
                secretKeyRef:
                  name: sentry
                  key: {{ .Release.Name }}.DSN.python
            {{- end }}
            {{- end }}
          volumeMounts:
            - name: etc-keystone
              mountPath: /etc/keystone
            - name: keystone-etc
              mountPath: /etc/keystone/keystone.conf
              subPath: keystone.conf
              readOnly: true
            - name: keystone-etc-confd
              mountPath: /etc/keystone/keystone.conf.d
            - name: keystone-etc
              mountPath: /etc/keystone/policy.yaml
              subPath: policy.yaml
              readOnly: true
            - name: keystone-etc
              mountPath: /etc/keystone/logging.conf
              subPath: logging.conf
              readOnly: true
            - name: fernet
              mountPath: /fernet-keys
              readOnly: true
            - name: upgrade
              mountPath: /upgrade
              readOnly: true
            - name: credential-keys
              mountPath: /credential-keys
              readOnly: true
            {{- include "utils.proxysql.volume_mount" . | indent 12 }}
            {{- include "utils.trust_bundle.volume_mount" . | indent 12 }}
        {{- if not .Values.proxysql.native_sidecar }}
        {{- include "utils.proxysql.container" . | indent 8 }}
        {{- end }}
      volumes:
        - name: etc-keystone
          emptyDir: {}
        - name: keystone-etc
          configMap:
            name: keystone-etc
            defaultMode: 0444
        - name: keystone-etc-confd
          secret:
            secretName: {{ .Release.Name }}-secrets
            defaultMode: 0444
        - name: upgrade
          configMap:
            name: {{ include "keystone.upgrade_config" . }}
        - name: fernet
          secret:
            secretName: keystone-fernet
            defaultMode: 0555
        - name: credential-keys
          secret:
            secretName: keystone-credential-keys
            defaultMode: 0555
        {{- include "utils.proxysql.volumes" . | indent 8 }}
        {{- include "utils.trust_bundle.volumes" . | indent 8 }}
{{ end -}}
{{- end -}}
