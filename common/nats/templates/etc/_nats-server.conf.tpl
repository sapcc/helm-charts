# Client port of 4222 on all interfaces
port: 4222

# HTTP monitoring port
monitor_port: 8222

# This is for clustering multiple servers together.
cluster {
  # It is recommended to set a cluster name
  name: "{{ include "nats.fullname" . }}"

  # Route connections to be received on any interface on port 6222
  port: 6222

  # Routes are protected, so need to use them with --routes flag
  # e.g. --routes=nats-route://ruser:T0pS3cr3t@otherdockerhost:6222
  authorization {
    user: {{ .Values.cluster.user }}
    password: {{ .Values.cluster.password | required "cluster.password required" }}
    timeout: {{ .Values.cluster.timeout }}
  }

  # Routes are actively solicited and connected to from this server.
  # This Docker image has none by default, but you can pass a
  # flag to the nats-server docker image to create one to an existing server.
  routes = [
    {{- range $host := .Values.cluster.routes }}
    nats://{{ $.Values.cluster.user }}:{{ $.Values.cluster.password }}@{{ $host }}:4222
    {{- end }}
  ]
}