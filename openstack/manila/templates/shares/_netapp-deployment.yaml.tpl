{{- define "share_netapp" -}}
{{$share := index . 1 -}}
{{with index . 0}}
{{- $imageRegistry := required ".Values.global.imageRegistry" .Values.global.imageRegistry -}}
{{- $imageNamespace := required ".Values.global.imageNamespace" .Values.global.imageNamespace -}}
{{- $imageVersion := required ".Values.imageVersionManilaApi" .Values.imageVersionManilaApi -}}
kind: Deployment
apiVersion: extensions/v1beta1
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
      annotations:
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-netapp-hash: {{ list . $share | include "share_netapp_configmap" | sha256sum }}
    spec:
      containers:
        - name: manila-share-netapp-{{$share.name}}
          {{- if .Values.loci.enabled }}
          image: {{$imageRegistry}}/{{.Values.loci.imageNamespace}}/loci-manila:{{.Values.loci.imageVersionLoci}}
          {{- else }}
          image: {{$imageRegistry}}/{{$imageNamespace}}/ubuntu-source-manila-share:{{$imageVersion}}
          {{- end }}
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
              {{- if eq .Values.mariadb.enabled true }}
              value: "{{ .Release.Name }}-mariadb,{{ .Release.Name }}-rabbitmq"
              {{- else }}
              value: "{{ .Release.Name }}-postgresql,{{ .Release.Name }}-rabbitmq"
              {{- end }}
            {{- if .Values.sentry.enabled }}
            - name: SENTRY_DSN
              valueFrom:
                secretKeyRef:
                  name: sentry
                  key: manila.DSN.python
            {{- end }}
          volumeMounts:
            - name: etcmanila
              mountPath: /etc/manila
            - name: manila-etc
              mountPath: /etc/manila/manila.conf
              subPath: manila.conf
              readOnly: true
            - name: manila-etc
              mountPath: /etc/manila/policy.json
              subPath: policy.json
              readOnly: true
            - name: manila-etc
              mountPath: /etc/manila/logging.ini
              subPath: logging.ini
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
            timeoutSeconds: 3
            periodSeconds: 10
            initialDelaySeconds: 15
          readinessProbe:
            exec:
              command:
              - grep
              - 'ready'
              - /etc/manila/probe
            timeoutSeconds: 3
            periodSeconds: 5
            initialDelaySeconds: 5
      hostname: manila-share-netapp-{{$share.name}}
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
