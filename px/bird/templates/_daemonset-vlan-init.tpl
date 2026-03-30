{{- define "daemonset_vlan_init" -}}
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: {{ printf "px-vlan%v-init" .domain_config.multus_vlan  }}
  labels: {{ include "bird.domain.labels" . | nindent 4 }}
    app.kubernetes.io/name: px-vlan-init
spec:
  selector:
    matchLabels: {{ include "bird.domain.labels" . | nindent 6 }}
      app.kubernetes.io/name: px-vlan-init
  template:
    metadata:
      labels: {{ include "bird.domain.labels" . | nindent 8 }}
        app.kubernetes.io/name: px-vlan-init
    spec:
{{- if .top.Values.hostNetworkDaemonSet.nodeSelector }}
      nodeSelector: {{ .top.Values.hostNetworkDaemonSet.nodeSelector | toYaml | nindent 8 }}
{{- end }}
{{- if .top.Values.hostNetworkDaemonSet.tolerations }}
      tolerations: {{ .top.Values.hostNetworkDaemonSet.tolerations | toYaml | nindent 8 }}
{{- end }}
      hostNetwork: true
      priorityClassName: system-node-critical
      initContainers:
      - name: create-vlan-interface
        image: keppel.{{ required "A registry must be set" .top.Values.registry }}.cloud.sap/{{ required "A bird_image must be set" .top.Values.bird_image }}
        command: ["/px-init/create_vlan_interface.sh"]
        securityContext:
          privileged: true
        env:
        - name: PX_NATIVE_INTERFACE
          value: {{ .domain_config.native_interface | required (printf "native_interface must be set for %s %s" .service .domain) }}
        - name: PX_INTERFACE
          value: {{ printf "vlan%s" (.domain_config.multus_vlan | toString) }}
        - name: PX_VLAN
          value: {{ .domain_config.multus_vlan | quote | required (printf "multus_vlan must be set for %s %s" .service .domain) }}
        volumeMounts:
        - name: init-host-network
          mountPath: /px-init/
      containers:
      - name: sleep
        image: keppel.{{ required "A registry must be set" .top.Values.registry }}.cloud.sap/{{ required "A bird_image must be set" .top.Values.bird_image }}
        command: ["/bin/sh", "-c", "trap : TERM INT; sleep infinity & wait"]
        resources:
          requests:
            cpu: "10m"
            memory: "16Mi"
          limits:
            cpu: "20m"
            memory: "32Mi"
      volumes:
        - name: init-host-network
          configMap:
            name: {{ printf "%s-init-host-network" .top.Release.Name | quote }}
            defaultMode: 0500
{{- end }}
