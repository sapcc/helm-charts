init_config:

instances:
 - name: Prometheus
   url: '{{.Values.monasca_agent_config_prometheus_url}}/federate'
   timeout: 45
   collect_response_time: True
   mapping:
      match_labels:

      dimensions:
         hostname:
           source_key: instance
           regex: '(.*?):?[0-9]*$'
         resource: resource
         quantile: quantile
      groups:
         dns:
             gauges: [ 'bind_up' ]
             rates: [ '(bind_incoming_queries)_total', '(bind_responses)_total' ]
             dimensions:
                 bind_server: kubernetes_name
                 type: type
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
             gauges: [ 'canary_(status)', 'canary_(off_status)' ]
             dimensions:
                 test: script
         prometheus:
             gauges: [ 'up' ]
             dimensions:
                 component: component
         activedirectory:
             gauges: [ 'ad_(.*_status)' ]
         kubernetes:
             gauges: [ 'kube_(node_status_ready)', 'kube_(node_status_out_of_disk)', 'node_filesystem_free', 'kube_(pod_status_phase)', 'kube_(pod_status_ready)' ]
             rates: [ 'kube_(pod_container_status_restarts)' ]
             dimensions:
                 container: container
                 namespace: namespace
                 pod: pod
                 phase: phase
                 hostname: node
                 mountpoint: mountpoint
                 fstype:
                     source_key: fstype
                     regex: '(xfs|ext4)'
                 condition: true
         openstack.api:
             rates: [ 'openstack_(responses)_by_api_counter', 'openstack_(requests)_total_counter' ]
             gauges: [ 'openstack_(latency)_by_api_timer' ]
             dimensions:
                 service: component
                 component: kubernetes_name
                 namespace: kubernetes_namespace
                 method: method
                 api: api
                 le: le
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
                 policy:   { regex: 'all' }
                 status:   status
                 type:     type

 - name: Prometheus-Aggregated
   url: '{{.Values.monasca_agent_config_prometheus_aggr_url}}/federate'
   timeout: 45
   collect_response_time: True
   match_labels:
       kubernetes_namespace:
        - monasca
        - ceilometer
   mapping:
       dimensions:
           resource: resource
           namespace: kubernetes_namespace
           pod: kubernetes_pod_name
           hostname: kubernetes_io_hostname
       groups:
           kubernetes:
               gauges: [ '(container_start_time_sec)onds', 'container_memory_usage_bytes' ]
               rates: [ '(container_cpu_usage_sec)onds_total', '(container_network.*_packages)_total' ]
               dimensions:
                   container: kubernetes_container_name
                   zone: zone
                   cgroup_path:
                       source_key: 'id'
                       regex: '(/system.slice/.*)'
