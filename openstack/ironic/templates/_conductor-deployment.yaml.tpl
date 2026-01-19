{{- define "ironic_conductor_deployment" }}
    {{- $conductor := index . 1 }}
    {{- with index . 0 }}
apiVersion: apps/v1
kind: Deployment
metadata:
{{- if $conductor.name }}
  name: ironic-conductor-{{$conductor.name}}
{{- else }}
  name: ironic-conductor
{{- end }}
  labels:
    system: openstack
    type: conductor
    component: ironic
  annotations:
    secret.reloader.stakater.com/reload: "{{ .Release.Name }}-secrets"
    deployment.reloader.stakater.com/pause-period: "60s"
spec:
  replicas: 1
  revisionHistoryLimit: {{ .Values.pod.lifecycle.upgrades.deployments.revisionHistory }}
  strategy:
    type: Recreate
  selector:
    matchLabels:
    {{- if $conductor.name }}
      name: ironic-conductor-{{$conductor.name}}
    {{- else }}
      name: ironic-conductor
    {{- end }}
  template:
    metadata:
      labels:
    {{- if $conductor.name }}
        name: ironic-conductor-{{$conductor.name}}
    {{- else }}
        name: ironic-conductor
    {{- end }}
{{ tuple . "ironic" "conductor" | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        kubectl.kubernetes.io/default-container: ironic-conductor
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        secrets-hash: {{ include (print .Template.BasePath "/secrets.yaml") . | sha256sum }}
        configmap-etc-conductor-hash: {{ tuple . $conductor | include "ironic_conductor_configmap" | sha256sum }}{{- if $conductor.jinja2 }}{{`
        configmap-etc-jinja2-hash: {{ block | safe | sha256sum }}
`}}{{- end }}
        {{- if or $conductor.default.statsd_enabled .Values.proxysql.mode }}
        prometheus.io/scrape: "true"
        prometheus.io/targets: {{ required ".Values.alerts.prometheus missing" .Values.alerts.prometheus | quote }}
        {{- end }}
        {{- include "utils.linkerd.pod_and_service_annotation" . | indent 8 }}
    spec:
      {{- include "utils.proxysql.pod_settings" . | indent 6 }}
      initContainers:
      {{- tuple . (dict "service" "ironic-api,ironic-rabbitmq") | include "utils.snippets.kubernetes_entrypoint_init_container" | indent 6 }}
      {{- if .Values.proxysql.native_sidecar }}
      {{- include "utils.proxysql.container" . | indent 6 }}
      {{- end }}
      containers:
      - name: ironic-conductor
        image: {{ .Values.global.registry }}/loci-ironic:{{ .Values.imageVersion }}
        imagePullPolicy: IfNotPresent
        {{- if $conductor.debug }}
        securityContext:
          runAsUser: 0
        {{- end }}
        command:
        {{- if not $conductor.debug }}
        - dumb-init
        - ironic-conductor
        {{- else }}
        - sleep
        - inf
        {{- end }}
        env:
        - name: PYTHONWARNINGS
          value: ignore:Unverified HTTPS request
        {{- if .Values.logging.handlers.sentry }}
        - name: SENTRY_DSN
          valueFrom:
            secretKeyRef:
              name: sentry
              key: {{ .Chart.Name }}.DSN.python
        {{- end }}
        - name: PGAPPNAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        {{- if not $conductor.debug }}
        resources:
{{ toYaml .Values.pod.resources.conductor | indent 10 }}
        {{- if $conductor.name }}
        startupProbe:
          exec:
            command:
            - bash
            - -c
            - curl --netrc-file /etc/ironic/netrc ironic-rabbitmq:{{ .Values.rabbitmq.ports.management }}/api/consumers | sed 's/,/\n/g' | grep ironic-conductor-{{$conductor.name}} >/dev/null
          periodSeconds: 10
          failureThreshold: 30
        livenessProbe:
          exec:
            command: [ "openstack-agent-liveness",  "--component", "ironic",  "--config-file", "/etc/ironic/ironic.conf", "--config-file", "/etc/ironic/ironic.conf.d/secrets.conf", "--ironic_conductor_host", "ironic-conductor-{{$conductor.name}}" ]
          periodSeconds: 120
          failureThreshold: 3
          timeoutSeconds: 12
        {{- end }}
        {{- end }}
        volumeMounts:
        - mountPath: /etc/ironic
          name: etcironic
        - mountPath: /etc/ironic/netrc
          name: curl-netrc
          subPath: netrc
        - mountPath: /etc/ironic/ironic.conf.d
          name: ironic-etc-confd
        - mountPath: /etc/ironic/ironic.conf
          name: ironic-etc
          subPath: ironic.conf
          readOnly: {{ not $conductor.debug }}
        - mountPath: /etc/ironic/policy.json
          name: ironic-etc
          subPath: policy.json
          readOnly: {{ not $conductor.debug }}
        - mountPath: /etc/ironic/rootwrap.conf
          name: ironic-etc
          subPath: rootwrap.conf
          readOnly: {{ not $conductor.debug }}
        - mountPath: /etc/ironic/rootwrap.d/ironic-images.filters
          name: ironic-etc
          subPath: ironic-images.filters
          readOnly: {{ not $conductor.debug }}
        - mountPath: /etc/ironic/rootwrap.d/ironic-utils.filters
          name: ironic-etc
          subPath: ironic-utils.filters
          readOnly: {{ not $conductor.debug }}
        - mountPath: /etc/ironic/logging.ini
          name: ironic-etc
          subPath: logging.ini
          readOnly: {{ not $conductor.debug }}
        - mountPath: /etc/ironic/ironic-conductor.conf
          name: ironic-conductor-etc
          subPath: ironic-conductor.conf
          readOnly: {{ not $conductor.debug }}
        - mountPath: /etc/ironic/ipxe_config.template
          name: ironic-conductor-etc
          subPath: ipxe_config.template
          readOnly: {{ not $conductor.debug }}
        - mountPath: /tftpboot
          name: ironic-tftp
        - mountPath: /shellinabox
          name: shellinabox
        {{- if $conductor.debug }}
        - mountPath: /development
          name: development
        {{- end }}
        {{- include "utils.proxysql.volume_mount" . | indent 8 }}
        {{- include "utils.trust_bundle.volume_mount" . | indent 8 }}
      {{- if not .Values.proxysql.native_sidecar }}
      {{- include "utils.proxysql.container" . | indent 6 }}
      {{- end }}
      - name: console
        image: {{ required ".Values.global.registry is missing" .Values.global.registry }}/{{ required ".Values.nginx.image is missing" .Values.nginx.image }}:{{ required ".Values.nginx.imageTag is missing" .Values.nginx.imageTag }}
        imagePullPolicy: IfNotPresent
        resources:
{{ toYaml .Values.pod.resources.console | indent 10 }}
        ports:
          - name: ironic-console
            protocol: TCP
            containerPort: 443
        volumeMounts:
          - mountPath: /etc/nginx/conf.d
            name: nginx-confd
          - mountPath: /etc/nginx/conf.d/default.conf
            name: ironic-console-nginxconf
            subPath: nginx.conf
          - mountPath: /etc/nginx/conf.d/dhparam.pem
            name: ironic-console-dhparam
            subPath: dhparam.pem
          - mountPath: /shellinabox
            name: shellinabox
          - mountPath: /etc/nginx/certs
            name: secret-tls
        livenessProbe:
          httpGet:
            path: /health
            port: ironic-console
            scheme: HTTPS
          initialDelaySeconds: 5
          periodSeconds: 3
        readinessProbe:
          httpGet:
            path: /health
            port: ironic-console
            scheme: HTTPS
          initialDelaySeconds: 5
          periodSeconds: 3
      {{- if $conductor.default.statsd_enabled }}
      - name: oslo-exporter
        image: {{ .Values.global.dockerHubMirror }}/prom/statsd-exporter
        args:
        - --statsd.mapping-config=/etc/statsd/statsd-rpc-exporter.yaml
        ports:
        - name: metrics
          containerPort: 9102
          protocol: TCP
        - name: statsd-udp
          containerPort: {{ $conductor.default.statsd_port }}
          protocol: UDP
        volumeMounts:
        - name: ironic-etc
          mountPath: /etc/statsd/statsd-rpc-exporter.yaml
          subPath: statsd-rpc-exporter.yaml
          readOnly: true
      {{- end }}
      volumes:
      - name: etcironic
        emptyDir: {}
      - name: shellinabox
        emptyDir: {}
      - name: ironic-etc-confd
        secret:
          secretName: {{ .Release.Name }}-secrets
          items:
          - key: secrets.conf
            path: secrets.conf
      - name: curl-netrc
        secret:
          secretName: {{ .Release.Name }}-secrets
          items:
          - key: netrc
            path: netrc
      - name: ironic-etc
        configMap:
          name: ironic-etc
      - name: ironic-conductor-etc
        configMap:
        {{- if $conductor.name }}
          name: ironic-conductor-{{$conductor.name}}-etc
        {{- else }}
          name: ironic-conductor-etc
        {{- end }}
      - name: nginx-confd
        emptyDir: {}
      - name: ironic-console-nginxconf
        secret:
          secretName: ironic-console-secret
          items:
          - key: nginx.conf
            path: nginx.conf
      - name: ironic-console-dhparam
        secret:
          secretName: {{ .Release.Name }}-secrets
          items:
          - key: dhparam.pem
            path: dhparam.pem
      - name: ironic-tftp
        persistentVolumeClaim:
          claimName: ironic-tftp-pvclaim
      {{- if $conductor.debug }}
      - name: development
        persistentVolumeClaim:
          claimName: development-pvclaim
      {{- end }}
      - name: secret-tls
        secret:
          secretName: tls-{{ include "ironic_console_endpoint_host_public" . | replace "." "-" }}
      {{- include "utils.proxysql.volumes" . | indent 6 }}
      {{- include "utils.trust_bundle.volumes" . | indent 6 }}
    {{- end }}
{{- end }}
