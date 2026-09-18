{{/*
webhook-injector sidecar — r7 target-patch mode.

Three corrections vs. the old _webhook-injector-sidecar.tpl:
  1. securityContext reads .Values.controllerManager.podSecurityContext
     (old template incorrectly read .Values.controllerManager.manager.podSecurityContext)
  2. r7 target-patch args: --webhook-config-name / --managed-resource-label /
     --external-host / --external-port removed (dead in r7); --target-label added;
     --target-kubeconfig kept so the injector watches the SHOOT, not the seed.
  3. image from pinned .Values.webhookInjector (not latest).
*/}}
{{- define "chart.webhook-injector-sidecar" -}}
- name: webhook-injector
  restartPolicy: Always
  image: {{ .Values.webhookInjector.repository }}:{{ .Values.webhookInjector.tag }}
  args:
    - "--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig"
    - "--target-label=dual-deployment-operator.cc.sap/webhook-injector=metal-operator"
    - "--leader-election-id=metal-operator-remote-webhook-injector-leader"
    - "--cert-secret-name=metal-operator-remote-cert-secret"
    - "--cert-sans=metal-operator-remote-webhook-service"
    - "--rotation-overlap-window=30s"
    - "--rotation-gate-timeout=30s"
  ports:
    - name: metrics
      containerPort: 8082
    - name: health
      containerPort: 8083
  securityContext:
    {{- toYaml .Values.controllerManager.podSecurityContext | nindent 4 }}
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi
  livenessProbe:
    httpGet:
      path: /healthz
      port: 8083
    initialDelaySeconds: 15
    periodSeconds: 20
    timeoutSeconds: 5
    failureThreshold: 3
  readinessProbe:
    httpGet:
      path: /readyz
      port: 8083
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
  volumeMounts:
    - name: webhook-certs
      mountPath: /tmp/webhook-certs
    - name: remote-serviceaccount
      mountPath: /var/run/secrets/kubernetes.io/remote-serviceaccount
      readOnly: true
    - name: remote-kubeconfig
      mountPath: /var/run/remote-kubeconfig
      readOnly: true
{{- end -}}
