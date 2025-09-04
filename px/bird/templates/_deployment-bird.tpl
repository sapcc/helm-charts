{{- define "deployment_bird" -}}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "bird.statefulset.name" . }}
  labels: {{ include "bird.statefulset.labels" . | nindent 4 }}
spec:
  serviceName: {{ .top.Release.Name }}
  replicas: {{ .top.Values.bird_replicas }}
  updateStrategy:
    type: RollingUpdate
  podManagementPolicy: OrderedReady
  ordinals:
    start: 1
  selector:
    matchLabels: {{ include "bird.statefulset.labels" . | nindent 8 }}
  template:
    metadata:
      labels: {{ include "bird.statefulset.labels" . | nindent 8 }}
        {{ include "bird.alert.labels" . | nindent 8 }}
        app.kubernetes.io/name: px
        kubectl.kubernetes.io/default-container: "bird"
{{ if not .top.Values.hostNetworking }}
      annotations:
        k8s.v1.cni.cncf.io/networks: '[{ "name": "vlan{{ .domain_config.multus_vlan }}", "interface": "vlan{{ .domain_config.multus_vlan }}"}]'
{{- end }}
    spec:
{{ if .top.Values.nodeSelector }}
      nodeSelector: {{ .top.Values.nodeSelector | toYaml | nindent 8 }}
{{- end }}
      priorityClassName: critical-payload
      topologySpreadConstraints: {{ include "bird.topology_spread" . | nindent 8 }}
      affinity: {{ include "bird.domain.affinity" . | nindent 8 }}
      tolerations: {{ include "bird.domain.tolerations" . | nindent 8 }}
      hostNetwork: {{ .top.Values.hostNetworking | default false }}
      initContainers:
{{ if .top.Values.hostNetworking }}
      - name: validate-native-interface
        image: keppel.{{ required "A registry mus be set" .top.Values.registry }}.cloud.sap/{{ required "A bird_image must be set" .top.Values.bird_image }}
        command: ["/px-init/validate_native_interface.sh"]
        env:
        - name: PX_NATIVE_INTERFACE
          value: {{ .domain_config.native_interface | required "native_interface must be set" }}
        volumeMounts:
          - name: init-host-network
            mountPath: /px-init/
      - name: create-vlan-interface
        image: keppel.{{ required "A registry mus be set" .top.Values.registry }}.cloud.sap/{{ required "A bird_image must be set" .top.Values.bird_image }}
        command: ["/px-init/create_vlan_interface.sh"]
        # I was unable to configure the VLAN interfaces with only CAP_NET_ADMIN and CAP_NET_RAW
        # so we need to run this init container with privileged mode.
        securityContext:
          privileged: true
        env:
        - name: PX_NATIVE_INTERFACE
          value: {{ .domain_config.native_interface | required "native_interface must be set" }}
        - name: PX_INTERFACE
          value: "vlan{{ .domain_config.multus_vlan | required "multus_vlan must be set" }}"
        - name: PX_VLAN
          value: {{ .domain_config.multus_vlan | quote }}
        volumeMounts:
          - name: init-host-network
            mountPath: /px-init/
{{- end }}
      - name: init-network
        image: keppel.{{ required "A registry mus be set" .top.Values.registry }}.cloud.sap/{{ required "A bird_image must be set" .top.Values.bird_image }}
        command: ["/px-init/configure_network.sh"]
        securityContext:
          privileged: true
        env:
        - name: PX_INTERFACE
          value: "vlan{{ .domain_config.multus_vlan | required "multus_vlan must be set" }}"
        - name: PX_NETWORK
          value: "{{ get .domain_config (printf "network_%s" .afi)}}"
        # needed for router id 
        - name: PX_NETWORK_V4
          value: {{ .domain_config.network_v4 | quote }}
        - name: STATEFULSET_ORDINAL
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['apps.kubernetes.io/pod-index']
        volumeMounts:
          - name: init-network
            mountPath: /px-init/
          - name: run-bird
            mountPath: /var/run/bird
      containers:
      - name: bird
        image: keppel.{{ required "A registry must be set" .top.Values.registry }}.cloud.sap/{{ required "A bird_image must be set" .top.Values.bird_image }}
        securityContext:
          capabilities:
            add: ["NET_ADMIN"]
{{ if .top.Values.hostNetworking }}
          privileged: true
{{- end }}
        imagePullPolicy: Always
{{- if .top.Values.hostNetworking }}
        lifecycle:
          preStop:
            exec:
              command: ["/px-cleanup/cleanup_vlan_interface.sh"]
{{- end }}
        volumeMounts:
        - name: config
          mountPath: /etc/bird
        - name: run-bird
          mountPath: /var/run/bird
{{- if .top.Values.hostNetworking }}
        - name: cleanup-host-network
          mountPath: /px-cleanup/
{{- end }}
        livenessProbe:
          exec:
            command: ["px", "status"]
          initialDelaySeconds: 5
          periodSeconds: 5
        resources: {{ toYaml .top.Values.resources.bird | nindent 10 }}
      - name: exporter
        image: keppel.{{ .top.Values.registry }}.cloud.sap/{{required "bird_exporter_image must be set" .top.Values.bird_exporter_image}}
        args: ["-format.new=true", "-bird.v2", "-bird.socket=/var/run/bird/bird.ctl", "-proto.ospf=false", "-proto.direct=false"]
        resources: {{ toYaml .top.Values.resources.exporter | nindent 10 }}
        volumeMounts:
        - name: run-bird
          mountPath: /var/run/bird
          readOnly: true
        ports:
        - containerPort: 9324
          name: metrics
      - name: lgproxy
        image: keppel.{{ .top.Values.registry }}.cloud.sap/{{ required "lg_image must be set" .top.Values.lg_image }}
        command: ["/venv/bin/python3"]
        args: ["lgproxy.py"]
        resources: {{ toYaml .top.Values.resources.proxy | nindent 10 }}
        volumeMounts:
        - name: run-bird
          mountPath: /var/run/bird
          readOnly: true
        ports:
        - containerPort: 5000
          name: lgproxy
      - name: lgadminproxy
        image: keppel.{{ .top.Values.registry }}.cloud.sap/{{ .top.Values.lg_image }}
        command: ["/venv/bin/python3"]
        args: ["lgproxy.py", "priv"]
        resources: {{ toYaml .top.Values.resources.proxy | nindent 10 }}
        volumeMounts:
        - name: run-bird
          mountPath: /var/run/bird
          readOnly: true
        ports:
        - containerPort: 5005
          name: lgadminproxy
      volumes:
        - name: config
          configMap:
            name: {{ include "bird.statefulset.configMapName" . }}
        - name: run-bird
          emptyDir: {}
        - name: init-network
          configMap:
            name: {{ printf "%s-init-network" .top.Release.Name | quote }}
            defaultMode: 0500
{{- if .top.Values.hostNetworking }}
        - name: init-host-network
          configMap:
            name: {{ printf "%s-init-host-network" .top.Release.Name | quote }}
            defaultMode: 0500
        - name: cleanup-host-network
          configMap:
            name: {{ printf "%s-cleanup-host-network" .top.Release.Name | quote }}
            defaultMode: 0500
{{- end }}
{{- end }}
