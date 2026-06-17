{{- define "chart.crd-injector" -}}
- name: crd-injector
  image: {{ .Values.webhookInjector.repository }}:{{ .Values.webhookInjector.tag }}
  command: ["/usr/bin/crd-injector"]
  args:
    - --configmap-name=ipam-capi-remote-crd-config
    - --target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig
  securityContext:
    {{- toYaml .Values.controllerManager.manager.podSecurityContext | nindent 4 }}
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi
  volumeMounts:
    - name: remote-serviceaccount
      mountPath: /var/run/secrets/kubernetes.io/remote-serviceaccount
      readOnly: true
    - name: remote-kubeconfig
      mountPath: /var/run/remote-kubeconfig
      readOnly: true
{{- end -}}
