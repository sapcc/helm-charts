{{- define "share_netapp" -}}
{{$share := index . 1 -}}
{{with index . 0}}
{{$availability_zone := $share.availability_zone | default .Values.default_availability_zone | default .Values.global.default_availability_zone }}
kind: Deployment
apiVersion: apps/v1
metadata:
  name: manila-share-netapp-{{$share.name}}
  labels:
    system: openstack
    type: backend
    component: manila
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
        name: manila-share-netapp-{{$share.name}}
  template:
    metadata:
      labels:
        name: manila-share-netapp-{{$share.name}}
        alert-tier: os
        alert-service: manila
      annotations:
        {{- if .Values.rpc_statsd_enabled }}
        prometheus.io/scrape: "true"
        prometheus.io/targets: {{ required ".Values.alerts.prometheus.openstack missing" .Values.alerts.prometheus.openstack | quote }}
        {{- end }}
        kubectl.kubernetes.io/default-container: manila-share-netapp-{{$share.name}}
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-netapp-hash: {{ list . $share | include "share_netapp_configmap" | sha256sum }}
    spec:
{{ tuple $availability_zone | include "kubernetes_pod_az_affinity" | indent 6 }}
      initContainers:
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
            - kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "manila-share --config-file /etc/manila/manila.conf --config-file /etc/manila/backend.conf"
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: DEPENDENCY_SERVICE
              value: "{{ .Release.Name }}-mariadb,{{ .Release.Name }}-rabbitmq"
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
            - name: manila-etc
              mountPath: /etc/manila/healthz
              subPath: healthz
              readOnly: true
            - name: backend-config
              mountPath: /etc/manila/backend.conf
              subPath: backend.conf
              readOnly: true
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
              - /etc/manila/healthz
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
      hostname: manila-share-netapp-{{$share.name}}
 {{- include "jaeger_agent_sidecar" . | indent 8 }}
      volumes:
        - name: etcmanila
          emptyDir: {}
        - name: manila-bin
          configMap:
            name: manila-bin
            defaultMode: 0555
        - name: manila-etc
          configMap:
            name: manila-etc
        - name: backend-config
          configMap:
            name: share-netapp-{{$share.name}}
{{ end }}
{{- end -}}
