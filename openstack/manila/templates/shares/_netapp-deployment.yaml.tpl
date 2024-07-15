{{- define "share_netapp" -}}
{{$share := index . 1 -}}
{{with index . 0}}
{{$availability_zone := $share.availability_zone | default .Values.default_availability_zone | default .Values.global.default_availability_zone }}
kind: Deployment
apiVersion: apps/v1
metadata:
  name: {{ .Release.Name }}-share-netapp-{{$share.name}}
  labels:
    system: openstack
    type: backend
    component: manila
  {{- if .Values.vpa.set_main_container }}
  annotations:
    vpa-butler.cloud.sap/main-container: manila-share-netapp-{{$share.name}}
  {{- end }}
spec:
  replicas: 1
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
        name: {{ .Release.Name }}-share-netapp-{{$share.name}}
  template:
    metadata:
      labels:
        name: {{ .Release.Name }}-share-netapp-{{$share.name}}
        alert-tier: os
        alert-service: manila
      annotations:
        {{- if or .Values.rpc_statsd_enabled .Values.proxysql.mode }}
        prometheus.io/scrape: "true"
        prometheus.io/targets: {{ required ".Values.alerts.prometheus.openstack missing" .Values.alerts.prometheus.openstack | quote }}
        {{- end }}
        kubectl.kubernetes.io/default-container: manila-share-netapp-{{$share.name}}
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-netapp-hash: {{ list . $share | include "share_netapp_configmap" | sha256sum }}
        secrets-hash: {{ include (print .Template.BasePath "/secrets.yaml") . | sha256sum }}
        {{- include "utils.linkerd.pod_and_service_annotation" . | indent 8 }}
    spec:
{{ tuple . $availability_zone | include "utils.kubernetes_pod_az_affinity" | indent 6 }}
{{ include "utils.proxysql.pod_settings" . | indent 6 }}
      initContainers:
      {{- tuple . (dict "service" (print .Release.Name "-mariadb," .Release.Name "-rabbitmq")) | include "utils.snippets.kubernetes_entrypoint_init_container" | indent 8 }}
        - name: fetch-rabbitmqadmin
          image: {{.Values.global.dockerHubMirror}}/library/busybox
          command: ["/scripts/fetch-rabbitmqadmin.sh"]
          volumeMounts:
            - name: manila-bin
              mountPath: /scripts
              readOnly: true
            - name: etcmanila
              mountPath: /shared
      containers:
        - name: manila-share-netapp-{{$share.name}}
          image: {{.Values.global.registry}}/loci-manila:{{.Values.loci.imageVersion}}
          imagePullPolicy: IfNotPresent
          command:
            - dumb-init
            {{- if .Values.pyreloader_enabled }}
            - pyreloader
            {{- end }}
            - manila-share
            - --config-file
            - /etc/manila/manila.conf
            - --config-file
            - /etc/manila/manila.conf.d/secrets.conf
            - --config-file
            - /etc/manila/backend.conf
            - --config-file
            - /etc/manila/backend-secret.conf
          env:
            {{- if .Values.sentry.enabled }}
            - name: SENTRY_DSN_SSL
              valueFrom:
                secretKeyRef:
                  name: sentry
                  key: manila.DSN
            - name: SENTRY_DSN
              value: $(SENTRY_DSN_SSL)?verify_ssl=0
            {{- end }}
          volumeMounts:
            - name: etcmanila
              mountPath: /etc/manila
            - name: manila-etc
              mountPath: /etc/manila/manila.conf
              subPath: manila.conf
              readOnly: true
            - name: manila-etc
              mountPath: /etc/manila/policy.yaml
              subPath: policy.yaml
              readOnly: true
            - name: manila-etc
              mountPath: /etc/manila/logging.ini
              subPath: logging.ini
              readOnly: true
            - name: manila-etc-confd
              mountPath: /etc/manila/manila.conf.d
            - name: backend-config
              mountPath: /etc/manila/backend.conf
              subPath: backend.conf
              readOnly: true
            - name: backend-secret
              mountPath: /etc/manila/backend-secret.conf
              subPath: backend-secret.conf
              readOnly: true
            {{- include "utils.proxysql.volume_mount" . | indent 12 }}
            {{- include "utils.trust_bundle.volume_mount" . | indent 12 }}
          {{- if .Values.pod.resources.share }}
          resources:
{{ toYaml .Values.pod.resources.share | indent 13 }}
          {{- end }}
          livenessProbe:
            exec:
              command:
              - cat
              - /etc/manila/probe
            initialDelaySeconds: 60
            periodSeconds: 10
            timeoutSeconds: 20
          readinessProbe:
            exec:
              command:
              - sh
              - /etc/manila/manila.conf.d/healthz
            timeoutSeconds: 10
            periodSeconds: 5
            initialDelaySeconds: 5
            failureThreshold: 1
        {{- if .Values.rpc_statsd_enabled }}
        - name: statsd
          image: {{ required ".Values.global.dockerHubMirror is missing" .Values.global.dockerHubMirror}}/prom/statsd-exporter:v0.8.1
          imagePullPolicy: IfNotPresent
          args: [ --statsd.mapping-config=/etc/statsd/statsd-rpc-exporter.yaml ]
          ports:
          - name: statsd
            containerPort: {{ .Values.rpc_statsd_port }}
            protocol: UDP
          - name: metrics
            containerPort: 9102
          volumeMounts:
            - name: manila-etc
              mountPath: /etc/statsd/statsd-rpc-exporter.yaml
              subPath: statsd-rpc-exporter.yaml
              readOnly: true
        {{- end }}
        {{- include "jaeger_agent_sidecar" . | indent 8 }}
        {{- include "utils.proxysql.container" . | indent 8 }}
      hostname: manila-share-netapp-{{$share.name}}
      volumes:
        - name: etcmanila
          emptyDir: {}
        - name: manila-bin
          configMap:
            name: {{ .Release.Name }}-bin
            defaultMode: 0555
        - name: manila-etc
          configMap:
            name: {{ .Release.Name }}-etc
        - name: manila-etc-confd
          secret:
            secretName: {{ .Release.Name }}-secrets
        - name: backend-config
          configMap:
            name: {{ .Release.Name }}-share-netapp-{{$share.name}}
        - name: backend-secret
          secret:
            secretName: {{ .Release.Name }}-share-netapp-{{$share.name}}-secret
        {{- include "utils.proxysql.volumes" . | indent 8 }}
        {{- include "utils.trust_bundle.volumes" . | indent 8 }}
{{ end }}
{{- end -}}
