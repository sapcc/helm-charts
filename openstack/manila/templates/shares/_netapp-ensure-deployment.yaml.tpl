{{- define "share_netapp_ensure" -}}
{{$share := index . 1 -}}
{{with index . 0}}
kind: Deployment
apiVersion: apps/v1
metadata:
  name: {{ .Release.Name }}-share-netapp-{{$share.name}}-ensure
  labels:
    system: openstack
    component: manila
  annotations:
    secret.reloader.stakater.com/reload: "{{ .Release.Name }}-secrets,{{ .Release.Name }}-share-netapp-{{$share.name}}-secret"
    deployment.reloader.stakater.com/pause-period: "60s"
  {{- if .Values.vpa.set_main_container }}
    vpa-butler.cloud.sap/main-container: reexport
  {{- end }}
spec:
  replicas: {{ .Values.pod.replicas.ensure }}
  revisionHistoryLimit: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
        name: {{ .Release.Name }}-share-netapp-{{$share.name}}-ensure
  template:
    metadata:
      labels:
        name: {{ .Release.Name }}-share-netapp-{{$share.name}}-ensure
        alert-tier: os
        alert-service: manila
      annotations:
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-netapp-hash: {{ list . $share | include "share_netapp_configmap" | sha256sum }}
        kubectl.kubernetes.io/default-container: reexport
        netapp_deployment-hash: {{ list . $share | include "share_netapp" | sha256sum }}
        secrets-hash: {{ include (print .Template.BasePath "/secrets.yaml") . | sha256sum }}
        {{- include "utils.linkerd.pod_and_service_annotation" . | indent 8 }}
    spec:
      affinity:
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: name
                  operator: In
                  values:
                  - {{ .Release.Name }}-share-netapp-{{$share.name}}
              topologyKey: kubernetes.io/hostname
      priorityClassName: {{ .Values.pod.priority_class.low }}
      initContainers:
      {{- tuple . (dict "service" (include "manila.db_service" .)) | include "utils.snippets.kubernetes_entrypoint_init_container" | indent 8 }}
      {{- if .Values.proxysql.native_sidecar }}
      {{- include "utils.proxysql.container" . | indent 8 }}
      {{- end }}
        - name: generate-backend-secret-conf
          image: {{.Values.global.dockerHubMirror}}/library/busybox
          command:
          - /bin/sh
          - -c
          - |
            cat <<EOF > /shared/backend-secret.conf
            {{- include "backendCredentialConf" .Values.global.netapp | indent 12 }}
            EOF
          env:
            {{- include "backendCredentialEnvs" .Values.global.netapp | indent 12 }}
          volumeMounts:
            - name: etcmanila
              mountPath: /shared
      containers:
        - name: reexport
          image: "{{.Values.global.registry}}/loci-manila:{{.Values.loci.imageVersion}}"
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
            - --reexport
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
            - mountPath: /manila-etc
              name: manila-etc
            - name: etcmanila
              mountPath: /etc/manila
            - name: manila-etc-confd
              mountPath: /etc/manila/manila.conf.d
            - name: manila-etc
              mountPath: /etc/manila/manila.conf
              subPath: manila.conf
              readOnly: true
            - name: manila-etc
              mountPath: /etc/manila/logging.ini
              subPath: logging.ini
              readOnly: true
            - name: backend-config
              mountPath: /etc/manila/backend.conf
              subPath: backend.conf
              readOnly: true
            {{- include "utils.proxysql.volume_mount" . | indent 12 }}
            {{- include "utils.trust_bundle.volume_mount" . | indent 12 }}
          {{- if .Values.pod.resources.share_ensure }}
          resources:
            {{ toYaml .Values.pod.resources.share_ensure | nindent 13 }}
          {{- end }}
          livenessProbe:
            exec:
              command:
              - cat
              - /etc/manila/probe
            timeoutSeconds: 3
            periodSeconds: 10
            initialDelaySeconds: 15
          readinessProbe:
            exec:
              command:
              - cat
              - /etc/manila/probe
            timeoutSeconds: 3
            periodSeconds: 5
            initialDelaySeconds: 5
        {{- include "jaeger_agent_sidecar" . | indent 8 }}
        {{- if not .Values.proxysql.native_sidecar }}
        {{- include "utils.proxysql.container" . | indent 8 }}
        {{- end }}
      volumes:
        - name: etcmanila
          emptyDir: {}
        - name: manila-etc
          configMap:
            name: manila-etc
        - name: manila-etc-confd
          secret:
            secretName: {{ .Release.Name }}-secrets
        - name: backend-config
          configMap:
            name: {{ .Release.Name }}-share-netapp-{{$share.name}}
        {{- include "utils.proxysql.volumes" . | indent 8 }}
        {{- include "utils.trust_bundle.volumes" . | indent 8 }}
{{ end }}
{{- end -}}
