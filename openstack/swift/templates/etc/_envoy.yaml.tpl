{{- define "envoy.yaml" -}}
node:
  id: lb
  cluster: swift-cluster
admin:
  access_log_path: /dev/stdout
  address:
    socket_address:
      protocol: TCP
      address: 0.0.0.0
      port_value: 9901
static_resources:
  listeners:
  - name: "prometheus"
    address:
      socket_address:
        address: "0.0.0.0"
        port_value: 9902
    filter_chains:
      - filters:
        - name: "envoy.filters.network.http_connection_manager"
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
            codec_type: auto
            stat_prefix: ingress_metrics
            route_config:
              name: local_route
              virtual_hosts:
              - name: local_service
                domains: ["*"]
                routes:
                - match:
                    prefix: "/metrics"
                  route:
                    cluster: envoy_admin
                    prefix_rewrite: "/stats/prometheus"
            http_filters:
            - name: envoy.filters.http.router
              typed_config: {}
  - name: https
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 443
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          access_log:
            name: envoy.access_loggers.file
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
              path: /dev/stdout
          stat_prefix: ingress_https
          use_remote_address: true
          xff_num_trusted_hops: 0
          skip_xff_append: false
          common_http_protocol_options:
            idle_timeout: {{ add .Values.client_timeout .Values.node_timeout 5 }}s
          route_config:
            name: swift-service
            virtual_hosts:
            - name: swift-service
              domains: ["*"]
              routes:
              - match: { prefix: "/" }
                route:
                  cluster: swift-cluster
                  idle_timeout: {{ add .Values.client_timeout 5 }}s
          http_filters:
          - name: envoy.filters.http.router
      transport_socket:
        name: envoy.transport_socket.tls
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
          common_tls_context:
            tls_params:
              tls_minimum_protocol_version: TLSv1_2
              tls_maximum_protocol_version: TLSv1_3
              cipher_suites: "[ECDHE-RSA-AES256-GCM-SHA384|ECDHE-RSA-AES128-GCM-SHA256]"
            tls_certificates:
            - certificate_chain: { filename: "/etc/envoy/certs/tls.crt" }
              private_key: { filename: "/etc/envoy/certs/tls.key" }
            validation_context:
              trusted_ca:
                filename: /etc/ssl/certs/ca-certificates.crt
  - name: http
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 80
    access_log:
      name: envoy.access_loggers.file
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
        path: /dev/stdout
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          access_log:
            name: envoy.access_loggers.file
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
              path: /dev/stdout
          stat_prefix: ingress_http
          use_remote_address: true
          xff_num_trusted_hops: 0
          skip_xff_append: false
          common_http_protocol_options:
            idle_timeout: {{ add .Values.client_timeout .Values.node_timeout 5 }}s
          route_config:
            name: swift-service
            virtual_hosts:
            {{ range $index, $san := .Values.sans_http -}}
            - name: swift-service
              domains: ["{{ $san }}.{{ $.Values.global.region }}.{{ $.Values.global.tld }}:{{ $.Values.proxy_public_http_port }}"]
              routes:
              - match: { prefix: "/" }
                route:
                  cluster: swift-cluster
                  idle_timeout: {{ add $.Values.client_timeout 5 }}s
            {{- end }}
            - name: redirect
              domains: ["*"]
              routes:
              - match: { prefix: "/" }
                redirect:
                  #path_redirect: "/"
                  https_redirect: true
          http_filters:
          - name: envoy.filters.http.router
  clusters:
  - name: swift-cluster
    connect_timeout: 10s
    type: STRICT_DNS
    load_assignment:
      cluster_name: swift-cluster
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: {{ printf "swift-proxy-internal-%s.swift.svc" .Values.cluster_name }}
                port_value: 8080
  - name: envoy_admin
    connect_timeout: 0.25s
    type: static
    load_assignment:
      cluster_name: envoy_admin
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: "127.0.0.1"
                port_value: 9901
{{ end }}
