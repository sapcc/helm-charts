{{- define "ironic_hypervisor" -}}
{{- $hypervisor := index . 1 -}}
{{- with index . 0 -}}
{{- $compute_hypervisor_name := printf "compute-%s" $hypervisor.name -}}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: nova-compute-{{$hypervisor.name}}
  labels:
    system: openstack
    type: backend
    component: nova
spec:
  replicas: 1
  revisionHistoryLimit: {{ .Values.pod.lifecycle.upgrades.deployments.revision_history }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 3
  selector:
    matchLabels:
      name: nova-compute-{{$hypervisor.name}}
  template:
    metadata:
      labels:
        name: nova-compute-{{$hypervisor.name}}
{{ tuple . "nova" $compute_hypervisor_name | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        pod.beta.kubernetes.io/hostname: nova-compute-{{$hypervisor.name}}
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-ironic-etc-hash: {{ tuple . $hypervisor | include "ironic_configmap" | sha256sum }}
    spec:
      hostname: nova-compute-{{$hypervisor.name}}
      containers:
        - name: nova-compute-{{$hypervisor.name}}
          image: {{.Values.global.imageRegistry}}/{{.Values.global.image_namespace}}/ubuntu-source-nova-compute:{{.Values.imageVersionNovaCompute | default .Values.imageVersion | required "Please set nova.imageVersion or similar" }}
          imagePullPolicy: IfNotPresent
          command:
            - kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "nova-compute"
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
{{- if or $hypervisor.python_warnings .Values.python_warnings }}
            - name: PYTHONWARNINGS
              value: {{ or $hypervisor.python_warnings .Values.python_warnings | quote }}
{{- end }}
            - name: PGAPPNAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          volumeMounts:
            - mountPath: /etc/nova
              name: etcnova
            - mountPath: /etc/nova/nova.conf
              name: nova-etc
              subPath: nova.conf
              readOnly: true
            - mountPath: /etc/nova/policy.json
              name: nova-etc
              subPath: policy.json
              readOnly: true
            - mountPath: /etc/nova/logging.ini
              name: nova-etc
              subPath: logging.ini
              readOnly: true
            - mountPath: /etc/nova/nova-compute.conf
              name: hypervisor-config
              subPath: nova-compute.conf
              readOnly: true
            - mountPath: /nova-patches
              name: nova-patches
      volumes:
        - name: etcnova
          emptyDir: {}
        - name: nova-etc
          configMap:
            name: nova-etc
        - name: nova-patches
          configMap:
            name: nova-patches
        - name: hypervisor-config
          configMap:
            name:  hypervisor-{{$hypervisor.name}}
{{- end -}}
{{- end -}}
