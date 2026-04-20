{{- define "metal-operator-remote.webhook-injector-sidecar" -}}
- name: webhook-injector
  image: {{ .Values.webhookInjector.image }}
  args:
    - --webhook-config-name=webhook-config
    - --namespace=kube-system
    - --target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig
  ports:
    - name: metrics
      containerPort: 8080
    - name: health
      containerPort: 8081
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    runAsUser: 65534
    capabilities:
      drop:
        - ALL
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
      port: 8081
    initialDelaySeconds: 15
    periodSeconds: 20
    timeoutSeconds: 5
    failureThreshold: 3
  readinessProbe:
    httpGet:
      path: /readyz
      port: 8081
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
