init_config:

instances:
 - name: Prometheus
   url: '{{.Values.monasca_agent_config_prometheus_url}}/federate'
   timeout: 45
   mapping:
      match_labels:

      dimensions:
         resource: resource
      groups:
         dns:
             gauges: [ 'bind_up' ]
             rates: [ '(bind_incoming_queries)_total', '(bind_responses)_total' ]
             dimensions:
                 bind_server: kubernetes_name
                 result: result
         datapath:
             gauges: [ 'datapath_(status)' ]
             dimensions:
                 test: script
         blackbox:
             gauges: [ 'blackbox_(status)' ]
             dimensions:
                 test: script
         canary:
             gauges: [ 'canary_(status)' ]
             dimensions:
                 test: script
         prometheus:
             gauges: [ 'up' ]
             dimensions:
                 instance: instance
                 component: component
         activedirectory:
             gauges: [ 'ad_(.*_status)' ]
         kubernetes:
             gauges: [ 'kube_(node_status_ready)', 'kube_(node_status_out_of_disk)', 'node_filesystem_free' ]
             dimensions:
                 node: node
                 node: instance
                 mountpoint: mountpoint
                 fstype:
                     source_key: fstype
                     regex: '(xfs|ext4)'
                 condition: condition
         openstack.api:
             rates: [ 'openstack_(responses)_by_api_counter', 'openstack_(requests)_total_counter' ]
             gauges: [ 'openstack_(latency)_by_api_timer' ]
             dimensions:
                 service: component
                 component: kubernetes_name
                 method: method
                 api: api
                 le: le
                 quantile: quantile
                 status: status
         monasca:
             gauges: [ 'monasca_(health.*)_gauge' ]
             dimensions:
                 service: service
         swift.cluster:
             gauges:
                 - 'swift_cluster_(drives_audit_errors)_gauge'
                 - 'swift_cluster_(drives_unmounted)_gauge'
                 - 'swift_cluster_(md5_ring_not_matched)_gauge'
                 - 'swift_cluster_(storage_used_percent)_gauge'
                 - 'swift_cluster_(storage_used_percent_by_disk)_gauge'
             dimensions:
                 storage_ip: storage_ip
                 disk: disk
         swift.dispersion:
             gauges:
                 - 'swift_dispersion_(container_overlapping)_gauge'
                 - 'swift_dispersion_(object_overlapping)_gauge'
         swift.proxy:
             gauges: [ 'swift_proxy_(firstbyte_timer)' ]
             dimensions:
                 policy:   { regex: '(all)' }
                 quantile: quantile
                 status:   status
                 type:     type

 - name: Prometheus-Aggregated
   url: '{{.Values.monasca_agent_config_prometheus_aggr_url}}/federate'
   timeout: 45
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
