{{- define "backup_deployment" -}}
{{- $volume := index . 1 -}}
{{- with index . 0 -}}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: cinder-backup-{{$volume.name}}
  labels:
    system: openstack
    type: backend
    component: cinder
spec:
  replicas: {{ .Values.pod.replicas.backup }}
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
{{ tuple . "cinder" "backup" | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        configmap-etc-hash: {{ include (print $.Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-volume-hash: {{ tuple . $volume | include "backup_configmap" | sha256sum }}
    spec:
{{- if and (eq .Capabilities.KubeVersion.Major "1") (ge .Capabilities.KubeVersion.Minor "7") }}
{{ tuple . "cinder" "backup" | include "kubernetes_pod_anti_affinity" | indent 6 }}
{{- end }}
      hostname: cinder-backup-{{$volume.name}}
      containers:
        - name: cinder-backup-{{$volume.name}}
          image: {{.Values.global.imageRegistry}}/{{.Values.global.image_namespace}}/ubuntu-source-cinder-backup:{{.Values.imageVersionCinderVolumeBackup | default .Values.imageVersion | required "Please set cinder.imageVersion or similar" }}
          imagePullPolicy: IfNotPresent
          command:
            - kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "cinder-backup"
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: DEPENDENCY_SERVICE
              value: "cinder-postgresql,rabbitmq"
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
            - name: PGAPPNAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          livenessProbe:
            httpGet:
              path: /
              port: cinder-backup
            initialDelaySeconds: 15
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /healthcheck
              port: cinder-backup
            initialDelaySeconds: 15
            timeoutSeconds: 5
          volumeMounts:
            - name: etccinder
              mountPath: /etc/cinder
            - name: cinder-etc
              mountPath: /etc/cinder/cinder.conf
              subPath: cinder.conf
              readOnly: true
            - name: cinder-etc
              mountPath: /etc/cinder/api-paste.ini
              subPath: api-paste.ini
              readOnly: true
            - name: cinder-etc
              mountPath: /etc/cinder/policy.json
              subPath: policy.json
              readOnly: true
            - name: cinder-etc
              mountPath: /etc/cinder/logging.ini
              subPath: logging.ini
              readOnly: true
            - name: cinder-etc
              mountPath: /etc/cinder/cinder_audit_map.yaml
              subPath: cinder_audit_map.yaml
              readOnly: true
      volumes:
        - name: etccinder
          emptyDir: {}
        - name: cinder-etc
          configMap:
            name: cinder-etc
        - name: volume-config
          configMap:
            name:  volume-{{$volume.name}}
{{- end -}}
{{- end -}}
