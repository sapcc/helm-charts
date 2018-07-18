{{- define "asr1k_deployment" -}}
{{- $context := index . 0 -}}
{{- $config_agent := index . 1 -}}
kind: Deployment

apiVersion: extensions/v1beta1

metadata:
  name: neutron-asr1k-{{ $config_agent.name }}
  labels:
    system: openstack
    type: backend
    component: neutron

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
      annotations:
        pod.beta.kubernetes.io/hostname:  {{ $config_agent.hostname }}
        prometheus.io/scrape: "true"
        prometheus.io/port: "{{$context.Values.port_l3_metrics |  default 9103}}"
        prometheus.io/port_1: "{{$context.Values.port_l2_metrics |  default 9102}}"
    spec:
      {{- if ge $context.Capabilities.KubeVersion.Minor "7" }}
      hostname:  {{ $config_agent.hostname }}
      {{- end }}
      containers:
        - name: neutron-asr1k
          image: {{ default "hub.global.cloud.sap" $context.Values.global.imageRegistry }}/{{$context.Values.image_name}}:{{$context.Values.image_tag}}
          imagePullPolicy: IfNotPresent
          command:
            - /container.init/neutron-asr1k-start
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
            - mountPath: /development
              name: development
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /neutron-etc-vendor
              name: neutron-etc-vendor
            - mountPath: /container.init
              name: container-init
          ports:
            - containerPort: {{$context.Values.port_l3_metrics |  default 9103}}
              name: metrics
              protocol: TCP

        - name: neutron-asr1k-ml2
          image: {{ default "hub.global.cloud.sap" $context.Values.global.imageRegistry }}/{{$context.Values.image_name}}:{{$context.Values.image_tag}}
          imagePullPolicy: IfNotPresent
          command:
            - /container.init/neutron-asr1k-ml2-start
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
              value: {{$context.Values.port_l2_metrics |  default 9102}}
          volumeMounts:
            - mountPath: /development
              name: development
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /neutron-etc-vendor
              name: neutron-etc-vendor
            - mountPath: /container.init
              name: container-init
          ports:
            - containerPort: {{$context.Values.port_l2_metrics |  default 9102}}
              name: metrics
              protocol: TCP
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
        - name: development
          persistentVolumeClaim:
            claimName: development-pvclaim
{{- end -}}
