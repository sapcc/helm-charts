{{- define "share_netapp_nanny" -}}
{{$share := index . 1 -}}
{{with index . 0}}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: manila-share-netapp-{{$share.name}}-nanny
  labels:
    system: openstack
    type: nanny
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
        name: manila-share-netapp-{{$share.name}}-nanny
  template:
    metadata:
      labels:
        name: manila-share-netapp-{{$share.name}}-nanny
{{/*      annotations:*/}}
{{/*        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}*/}}
{{/*        configmap-netapp-hash: {{ list . $share | include "share_netapp_configmap" | sha256sum }}*/}}
    spec:
      containers:
        - name: reexport
          image: "{{.Values.global.imageRegistry}}/monsoon/netapp-manila-nanny:{{.Values.manila_nanny.image_version}}"
          imagePullPolicy: IfNotPresent
          command:
            - dumb-init
            - kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "{{ if not .Values.manila_nanny.debug }}/bin/bash /scripts/netapp-manila-reexport.sh{{ else }}sleep inf{{ end }}"
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: DEPENDENCY_SERVICE
{{- if eq .Values.manila_nanny.mariadb.enabled true }}
              value: "{{ .Release.Name }}-mariadb,{{ .Release.Name }}-api"
{{- else }}
              value: "{{ .Release.Name }}-postgresql,{{ .Release.Name }}-api"
{{- end }}
            - name: MANILA_NETAPP_NANNY_INTERVAL
              value: {{ .Values.manila_nanny.netapp.interval | quote }}
            {{- if .Values.sentry.enabled }}
            - name: SENTRY_DSN
              valueFrom:
                secretKeyRef:
                  name: sentry
                  key: manila.DSN.python
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
          {{- if .Values.manila_nanny.netapp.resources }}
          resources:
            {{ toYaml .Values.manila_nanny.netapp.resources | nindent 13 }}
          {{- else if .Values.manila_nanny.resources }}
          resources:
            {{ toYaml .Values.manila_nanny.resources | nindent 13 }}
          {{- end }}
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
