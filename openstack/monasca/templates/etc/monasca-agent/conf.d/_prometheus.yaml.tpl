#
# IMPORTANT: please be aware, that below there are two sections: one for the prometheus collector
#            and another one for the prometheus frontend - make sure you enter your metric conversion
#            config to the proper section
# IMPORTANT: please keep in mind that each instance section below might contain a match_label re-
#            striction and make sure, that everything you add is properly matched in there
#

init_config:

instances:
 - name: Prometheus
   url: '{{.Values.monasca_agent_config_prometheus_url}}/federate'
   timeout: 45
   collect_response_time: True
   mapping:
      # see https://github.com/sapcc/monasca-agent/blob/master/docs/Customizations.md#dynamiccheckhelper-class for
      # help on filter and mapping rules below
      # The following dimensions have a predefined-meaning and should be used properly
      #   service: the service name (e.g. "compute", "dns", "monitoring", "object-store", "kubernetes", "elektra")
      #   component: the technical component of the service (e.g. "Postgres", "nova-api", ...)
      #
      # Use `monasca --insecure dimension-name-list` to discover existing names and try to match existing names first.
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
         swift.healthcheck:
             gauges:
                 - 'swift_health_statsd_(exit_code)_gauge'
         swift.proxy:
             gauges: [ 'swift_proxy_(firstbyte_timer)' ]
             dimensions:
                 policy:     { regex: 'all' }
                 status:     status
                 type:       type
                 os_cluster: os_cluster
         swift.object:
             gauges:
                 - 'swift_object_server_(async_pendings)_counter'
         nova:
             gauges: [ 'openstack_compute_(.*)_gauge' ]
             dimensions:
                 hostname:  host
                 service: service
#                 hypervisor_type: hypervisor_type
                 vm_state: vm_state
                 project_id: project_id        # NOT: __project_id__ !!
 - name: Prometheus-Aggregated
   url: '{{.Values.monasca_agent_config_prometheus_aggr_url}}/federate'
   timeout: 45
   collect_response_time: True
   match_labels:
       kubernetes_namespace:
        - monasca
        - ceilometer
        - lyra
        - limes
        - arc
        - elektra
        - blackbox
        - monsoon3
        - swift
   mapping:
# taking the dimensions out for now, as they are empty
#       dimensions:
       groups:
           kubernetes:
               gauges: [ '(container_start_time_sec)onds', 'container_memory_usage_bytes' ]
               rates: [ '(container_cpu_usage_sec)onds_total', '(container_network.*_packages)_total' ]
               dimensions:
# those four dimensions are moved here from the global section - are they really required?
                   resource: resource
                   namespace: kubernetes_namespace
                   pod: kubernetes_pod_name
                   hostname: kubernetes_io_hostname
# end of moved section
                   container: kubernetes_container_name
                   zone: zone
                   cgroup_path:
                       source_key: 'id'
                       regex: '(/system.slice/.*)'
           postgres:
               gauges: [ 'pg_(database_size_bytes)' ]
               dimensions:
                   service: kubernetes_namespace
                   database: datname
                   region: region
           puma:
               counters: [ 'puma_(request_backlog)' ]
               dimensions:
                   service: kubernetes_namespace
                   pod: kubernetes_pod_name
                   region: region
           blackbox.healthcheck:
               gauges: [ 'blackbox_(.*_status)_gauge' ]
               dimensions:
                   test: check
                   region: region
           limes:
               gauges: [ 'limes_(failed_scrapes)_rate' ]
               dimensions:
                   cluster: cluster
                   service: service
           swift:
               gauges: [ 'swift_(async_pendings)_rate' ]
           networking-dvs:
               gauges: [ 'openstack_networking_dvs_(.*)_timer', 'openstack_networking_dvs_(.*)_timer_count' ]
               dimensions:
                   pod: pod_template_hash
                   region: region
                   host: name
                   quantile: quantile
