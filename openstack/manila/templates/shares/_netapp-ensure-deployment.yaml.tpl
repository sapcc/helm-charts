{{- define "share_netapp_ensure" -}}
{{$share := index . 1 -}}
{{with index . 0}}
kind: Deployment
apiVersion: apps/v1
metadata:
  name: manila-share-netapp-{{$share.name}}-ensure
  labels:
    system: openstack
    component: manila
spec:
  replicas: 1
  revisionHistoryLimit: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
        name: manila-share-netapp-{{$share.name}}-ensure
  template:
    metadata:
      labels:
        name: manila-share-netapp-{{$share.name}}-ensure
        alert-tier: os
        alert-service: manila
      annotations:
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-netapp-hash: {{ list . $share | include "share_netapp_configmap" | sha256sum }}
        netapp_deployment-hash: {{ list . $share | include "share_netapp" | sha256sum }}
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
                  - manila-share-netapp-{{$share.name}}
              topologyKey: kubernetes.io/hostname
      containers:
        - name: reexport
          image: "{{.Values.global.registry}}/manila-ensure:{{.Values.loci.imageVersionEnsure}}"
          imagePullPolicy: IfNotPresent
          command:
            - dumb-init
            - kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "/bin/bash /scripts/manila-ensure-reexport.sh"
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: DEPENDENCY_SERVICE
              value: "{{ .Release.Name }}-mariadb"
            - name: MANILA_NETAPP_ENSURE_INTERVAL
              value: "240"
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
      volumes:
        - name: etcmanila
          emptyDir: {}
        - name: manila-etc
          configMap:
            name: manila-etc
        - name: backend-config
          configMap:
            name: share-netapp-{{$share.name}}
{{ end }}
{{- end -}}
