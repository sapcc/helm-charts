{{- define "deployment_bird" -}}
{{- $values := index . 0 }}
{{- $deployment_name := index . 1 | required "deployment_name cannot be empty" }}
{{- $service_number := index . 2 }}
{{- $service := index . 3 }}
{{- $domain_number := index . 4}}
{{- $domain_config := index . 5 }}
initContainers:
- name: {{ $deployment_name }}-init
  image: keppel.{{ required "A registry mus be set" $values.registry }}.cloud.sap/ccloud-dockerhub-mirror/library/alpine:latest
  command: ["sh", "-c", "ip link set vlan{{ $domain_config.multus_vlan }} promisc on"]
  securityContext:
    privileged: true
containers:
- name: {{ $deployment_name }}
  image: keppel.{{ required "A registry mus be set" $values.registry }}.cloud.sap/{{ required "A bird_image must be set" $values.bird_image }}
  securityContext:
    capabilities:
      add: ["NET_ADMIN"]
  imagePullPolicy: Always
  volumeMounts:
  - name: vol-{{ $deployment_name }}
    mountPath: /etc/bird
  - name: bird-socket
    mountPath: /var/run/bird
  livenessProbe:
    exec:
      command: ["px", "status"]
    initialDelaySeconds: 5
    periodSeconds: 5
  resources:
{{ toYaml $values.resources.bird | indent 4 }}
- name: {{ $deployment_name }}-exporter
  image: keppel.{{ $values.registry }}.cloud.sap/{{required "bird_exporter_image must be set" $values.bird_exporter_image}}
  args: ["-format.new=true", "-bird.v2", "-bird.socket=/var/run/bird/bird.ctl", "-proto.ospf=false", "-proto.direct=false"]
  resources:
{{ toYaml $values.resources.exporter | indent 4 }}
  volumeMounts:
  - name: bird-socket
    mountPath: /var/run/bird
    readOnly: true
  ports:
  - containerPort: 9324
    name: metrics
- name: {{ $deployment_name }}-lgproxy
  image: keppel.{{ $values.registry }}.cloud.sap/{{ required "lg_image must be set" $values.lg_image }}
  command: ["python3"]
  args: ["lgproxy.py"]
  resources:
{{ toYaml $values.resources.proxy | indent 4 }}
  volumeMounts:
  - name: bird-socket
    mountPath: /var/run/bird
    readOnly: true
  ports:
  - containerPort: 5000
    name: lgproxy
- name: {{ $deployment_name }}-lgadminproxy
  image: keppel.{{ $values.registry }}.cloud.sap/{{ $values.lg_image }}
  command: ["python3"]
  args: ["lgproxy.py", "priv"]
  resources:
{{ toYaml $values.resources.proxy | indent 4 }}
  volumeMounts:
  - name: bird-socket
    mountPath: /var/run/bird
    readOnly: true
  ports:
  - containerPort: 5005
    name: lgadminproxy
volumes:
  - name: vol-{{ $deployment_name }}
    configMap:
      name: cfg-{{ $values.global.region }}-pxrs-{{ $domain_number }}-s{{ $service_number }}
  - name: bird-socket
    emptyDir: {}
{{- end }}
