{{- define "asr1k_deployment" -}}
{{- $context := index . 0 -}}
{{- $config_agent := index . 1 -}}
kind: Deployment

apiVersion: apps/v1

metadata:
  name: neutron-asr1k-{{ $config_agent.name }}
  labels:
    system: openstack
    type: backend
    component: neutron
  {{- if $context.Values.vpa.set_main_container }}
  annotations:
    vpa-butler.cloud.sap/main-container: neutron-asr1k
  {{- end }}
spec:
  replicas: 1
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 3
  selector:
    matchLabels:
      name: neutron-asr1k-{{ $config_agent.name }}
  template:
    metadata:
      labels:
        name: neutron-asr1k-{{ $config_agent.name }}
        cloud.sap/scheduling-disabled: {{ or ($config_agent.scheduling_disabled | default false) ($config_agent.decommissioning | default false) | quote }}
        cloud.sap/decommissioning: {{ $config_agent.decommissioning | default false | quote }}
{{ tuple $context "neutron" "asr1k-agent" | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        pod.beta.kubernetes.io/hostname:  asr1k-{{ $config_agent.name }}
        prometheus.io/scrape: "true"
        prometheus.io/targets: {{ required ".Values.metrics.prometheus missing" $context.Values.metrics.prometheus | quote }}
        configmap-asr1k-{{ $config_agent.name }}: {{ tuple $context $config_agent |include "asr1k_configmap" | sha256sum  }}
        {{- include "utils.linkerd.pod_and_service_annotation" $context | indent 8 }}
    spec:
      hostname:  asr1k-{{ $config_agent.name }}
      containers:
        - name: neutron-asr1k
          image: {{$context.Values.global.registry}}/loci-neutron:{{$context.Values.imageVersionASR1k | default $context.Values.imageVersion | required "Please set neutron.imageVersionASR1k or similar"}}
          imagePullPolicy: IfNotPresent
          command:
            - /container.init/neutron-asr1k-start
          livenessProbe:
            exec:
              command: ["neutron-agent-liveness", "--agent-type", "ASR1K L3 Agent", "--config-file", "/etc/neutron/neutron.conf", "--config-file", "/etc/neutron/secrets/neutron-common-secrets.conf"]
            initialDelaySeconds: 30
            periodSeconds: 30
            timeoutSeconds: 10
          env:
            - name: DEBUG_CONTAINER
            {{ if $context.Values.pod.debug.asr1k_agent }}
              value: "true"
            {{else}}
              value: "false"
            {{ end }}
            - name: SENTRY_DSN
              valueFrom:
                secretKeyRef:
                  name: sentry
                  key: neutron.DSN.python
            - name: METRICS_PORT
              value: "{{$context.Values.port_l3_metrics |  default 9103 }}"
          volumeMounts:
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /etc/neutron/secrets/neutron-common-secrets.conf
              name: neutron-common-secrets
              subPath: neutron-common-secrets.conf
              readOnly: true
            - mountPath: /etc/neutron/secrets/asr1k_secrets.conf
              name: neutron-etc-asr1k-secrets
              subPath: asr1k_secrets.conf
              readOnly: true
            - mountPath: /neutron-etc-vendor
              name: neutron-etc-vendor
            - mountPath: /neutron-etc-asr1k
              name: neutron-etc-asr1k
            - mountPath: /container.init
              name: container-init
          ports:
            - containerPort: {{$context.Values.port_l3_metrics |  default 9103}}
              name: metrics-l3
              protocol: TCP
          resources:
{{ toYaml $context.Values.pod.resources.asr1k | indent 12 }}

        - name: neutron-asr1k-ml2
          image: {{$context.Values.global.registry}}/loci-neutron:{{$context.Values.imageVersionASR1kML2 | default $context.Values.imageVersionASR1k | default $context.Values.imageVersion | required "Please set neutron.imageVersionASR1kML2 or similar"}}
          imagePullPolicy: IfNotPresent
          command:
            - /container.init/neutron-asr1k-ml2-start
          livenessProbe:
            exec:
              command: ["neutron-agent-liveness", "--agent-type", "ASR1K ML2 Agent", "--config-file", "/etc/neutron/neutron.conf", "--config-file", "/etc/neutron/secrets/neutron-common-secrets.conf"]
            initialDelaySeconds: 30
            periodSeconds: 30
            timeoutSeconds: 10
          env:
            - name: DEBUG_CONTAINER
            {{ if $context.Values.pod.debug.asr1k_ml2_agent }}
              value: "true"
            {{else}}
              value: "false"
            {{ end }}
            - name: SENTRY_DSN
              valueFrom:
                secretKeyRef:
                  name: sentry
                  key: neutron.DSN.python
            - name: METRICS_PORT
              value: "{{$context.Values.port_l2_metrics |  default 9102}}"
          volumeMounts:
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /etc/neutron/secrets/neutron-common-secrets.conf
              name: neutron-common-secrets
              subPath: neutron-common-secrets.conf
              readOnly: true
            - mountPath: /etc/neutron/secrets/asr1k_secrets.conf
              name: neutron-etc-asr1k-secrets
              subPath: asr1k_secrets.conf
              readOnly: true
            - mountPath: /neutron-etc-vendor
              name: neutron-etc-vendor
            - mountPath: /neutron-etc-asr1k
              name: neutron-etc-asr1k
            - mountPath: /container.init
              name: container-init
          ports:
            - containerPort: {{$context.Values.port_l2_metrics |  default 9102}}
              name: metrics-l2
              protocol: TCP
          resources:
{{ toYaml $context.Values.pod.resources.asr1k_ml2 | indent 12 }}
      volumes:
        - name: neutron-etc
          configMap:
            name: neutron-etc
        - name: neutron-etc-vendor
          configMap:
            name: neutron-etc-vendor
        - name: container-init
          configMap:
            name: neutron-bin-vendor
            defaultMode: 0755
        - name:  neutron-etc-asr1k
          configMap:
            name: neutron-etc-asr1k-{{ $config_agent.name }}
        - name: neutron-common-secrets
          secret:
            secretName: neutron-common-secrets
        - name: neutron-etc-asr1k-secrets
          secret:
            secretName: neutron-etc-asr1k-secrets-{{$config_agent.name}}
{{- end -}}
