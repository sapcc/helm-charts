{{- define "monasca_agent_conf_d_prometheus_yaml_tpl" -}}
init_config:

instances:
 - name: Prometheus
   url: '{{.Value.monasca_agent_config_prometheus.url}}/federate'
   timeout: 30
   mapping:
      match_labels:

      dimensions:
         resource: resource
      groups:
         dns.bind:
             gauges: [ 'bind_(up)' ]
             rates: [ 'bind_(incoming_queries)_total', 'bind_(responses)_total' ]
             dimensions:
                 dns.bind_server: kubernetes_name
         datapath:
             gauges: [ 'datapath_(status)' ]
             dimensions:
                 service: script
         blackbox:
             gauges: [ 'blackbox_(status)' ]
             dimensions:
                 service: script
         canary:
             gauges: [ 'canary_(status)' ]
             dimensions:
                 test: script
                 service: service
         activedirectory:
             gauges: [ 'ad_(.*_status)' ]
         kubernetes:
             gauges: [ 'kube_(node_status_ready)', 'kube_(node_status_out_of_disk)' ]
             dimensions:
                 node: node
                 condition: condition
         openstack.api:
             rates: [ 'openstack_(responses)_by_api_counter', 'openstack_(requests)_total_counter' ]
             gauges: [ 'openstack_(latency)_by_api_timer' ]
             dimensions:
                 service: component
                 component: kubernetes_name
                 method: method
                 api: api
                 method: method
                 le: le
                 quantile: quantile
                 status: status
         monasca:
             gauges: [ 'monasca_(health.*)_gauge' ]
             dimensions:
                 service: service

 - name: Prometheus-Aggregated
   url: '{{.Values.monasca_agent_config_prometheus_aggr_url}}/federate'
   timeout: 30
   match_labels:
       kubernetes_namespace:
        - monsoon3
        - monasca
        - ceilometer
        - keystone
        - swift
        - elektra
        - lyra
   mapping:
       dimensions:
           resource: resource
           kubernetes.namespace: kubernetes_namespace
           kubernetes.pod_name: kubernetes_pod_name
           hostname: kubernetes_io_hostname
       groups:
           kubernetes:
               gauges: [ '(container_start_time_sec)onds', 'container_memory_usage_bytes' ]
               rates: [ '(container_cpu_usage_sec)onds_total', '(container_network.*_packages)_total' ]
               dimensions:
                   kubernetes.container_name: kubernetes_container_name
                   kubernetes.zone: zone
                   kubernetes.cgroup.path:
                       source_key: 'id'
                       regex: '(/system.slice/.*)'
{{ end }}
