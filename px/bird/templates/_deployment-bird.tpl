{{- define "deployment_bird" -}}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "bird.instance.deployment_name" . }}
  labels: {{ include "bird.instance.labels" . | nindent 4 }}
spec:
  replicas: 1
  updateStrategy:
    type: RollingUpdate
  podManagementPolicy: OrderedReady
  ordinals:
    start: 1
  selector:
    matchLabels: {{ include "bird.instance.labels" . | nindent 8 }}
  template:
    metadata:
      labels: {{ include "bird.instance.labels" . | nindent 8 }}
        {{ include "bird.alert.labels" . | nindent 8 }}
        app.kubernetes.io/name: px
        kubectl.kubernetes.io/default-container: "bird"
      annotations:
        k8s.v1.cni.cncf.io/networks: '[{ "name": "{{ include "bird.instance.deployment_name" . }}", "interface": "vlan{{ .domain_config.multus_vlan }}"}]'
    spec:
      affinity: {{ include "bird.domain.affinity" . | nindent 8 }}
      tolerations: {{ include "bird.domain.tolerations" . | nindent 8 }}
      initContainers:
      - name: init-network
        image: keppel.{{ required "A registry mus be set" .top.Values.registry }}.cloud.sap/ccloud-dockerhub-mirror/library/alpine:latest
        command: ["sh", "-c", "ip link set vlan{{ .domain_config.multus_vlan }} promisc on"]
        securityContext:
          privileged: true
      containers:
      - name: bird
        image: keppel.{{ required "A registry mus be set" .top.Values.registry }}.cloud.sap/{{ required "A bird_image must be set" .top.Values.bird_image }}
        securityContext:
          capabilities:
            add: ["NET_ADMIN"]
        imagePullPolicy: Always
        volumeMounts:
        - name: config
          mountPath: /etc/bird
        - name: bird-socket
          mountPath: /var/run/bird
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
        - name: bird-socket
          mountPath: /var/run/bird
          readOnly: true
        ports:
        - containerPort: 9324
          name: metrics
      - name: lgproxy
        image: keppel.{{ .top.Values.registry }}.cloud.sap/{{ required "lg_image must be set" .top.Values.lg_image }}
        command: ["python3"]
        args: ["lgproxy.py"]
        resources: {{ toYaml .top.Values.resources.proxy | nindent 10 }}
        volumeMounts:
        - name: bird-socket
          mountPath: /var/run/bird
          readOnly: true
        ports:
        - containerPort: 5000
          name: lgproxy
      - name: lgadminproxy
        image: keppel.{{ .top.Values.registry }}.cloud.sap/{{ .top.Values.lg_image }}
        command: ["python3"]
        args: ["lgproxy.py", "priv"]
        resources: {{ toYaml .top.Values.resources.proxy | nindent 10 }}
        volumeMounts:
        - name: bird-socket
          mountPath: /var/run/bird
          readOnly: true
        ports:
        - containerPort: 5005
          name: lgadminproxy
      volumes:
        - name: config
          configMap:
            name: {{ include "bird.domain.config_name" . }}
        - name: bird-socket
          emptyDir: {}
{{- end }}
