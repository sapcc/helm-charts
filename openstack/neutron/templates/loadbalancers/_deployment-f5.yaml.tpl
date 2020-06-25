{{- define "f5_deployment" -}}
{{- $context := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
kind: Deployment
{{- if $context.Capabilities.APIVersions.Has "apps/v1" }}
apiVersion: apps/v1
{{- else }}
apiVersion: extensions/v1beta1
{{- end }}

metadata:
  name: neutron-f5agent-{{ $loadbalancer.name }}
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
      name: neutron-f5agent-{{ $loadbalancer.name }}
  template:
    metadata:
      labels:
        name: neutron-f5agent-{{ $loadbalancer.name }}
      annotations:
        pod.beta.kubernetes.io/hostname:  f5-{{ $loadbalancer.name }}
    spec:
      hostname:  {{ $loadbalancer.name }}
      containers:
        - name: neutron-f5agent-{{ $loadbalancer.name }}
          image: {{ default "hub.global.cloud.sap" $context.Values.global.imageRegistry }}/monsoon/loci-neutron:{{ $context.Values.imageVersionF5 | default $context.Values.imageVersion | required "Please set neutron.imageVersionF5 or similar"}}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - /container.init/neutron-f5-agent-start
          env:
            - name: DEBUG_CONTAINER
              value: "false"
            - name: SENTRY_DSN
              valueFrom:
                secretKeyRef:
                  name: sentry
                  key: neutron.DSN.python
          volumeMounts:
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /f5-etc
              name: f5-etc
            - mountPath: /neutron-etc-vendor
              name: neutron-etc-vendor
            - mountPath: /f5-patches
              name: f5-patches
            - mountPath: /container.init
              name: container-init
            - mountPath: /development
              name: development
      volumes:
        - name: neutron-etc
          configMap:
            name: neutron-etc
        - name: neutron-etc-vendor
          configMap:
            name: neutron-etc-vendor
        - name: f5-patches
          configMap:
            name: f5-patches
        - name: f5-etc
          configMap:
            name: neutron-f5-etc-{{$loadbalancer.name}}
        - name: development
          persistentVolumeClaim:
            claimName: development-pvclaim
        - name: container-init
          configMap:
            name: neutron-bin-vendor
            defaultMode: 0755
{{- end -}}