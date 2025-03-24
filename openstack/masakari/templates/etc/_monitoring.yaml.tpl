openstack:
  - name: default
    interval: 60
    compute_interface: internal
    ha_interface: internal
    notification_wait_time: 3600 # do not host ha more than one per hour
    exporter:
      listen: 0.0.0.0:{{ .Values.monitoringExporterPort }}
      string_to_bool:
        - good
        - online
        - up
    netbox:
      url: https://netbox.global.cloud.sap
      devices_query:
        platform: linux-kvm
        region: {{ .Values.global.region }}
      devices_field_match: netbox_field("name") == str::regex_find("node[0-9]{3}-(bb|ap)[0-9]{2,3}", hypervisor("service.host"))
      interval: 30
    settings:
      username: masakari
      password: {{ .Values.global.masakari_service_password }}
      domain_name: default
      project_domain_name: default
      project_name: service
      auth_url: {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}
    segments:
      - name: prod-green
        recovery_method: reserved_host
        match: |
          str::regex_matches(hypervisor("hypervisor_type"), "QEMU") &&
          str::regex_matches(hypervisor("hypervisor_hostname"), "shoot--ccloud.*green.*")
        reserved:
          aggregates:
            - failover
      - name: prod-blue
        recovery_method: auto
        match: |
          str::regex_matches(hypervisor("hypervisor_type"), "QEMU") &&
          str::regex_matches(hypervisor("hypervisor_hostname"), "shoot--ccloud.*blue.*")
      - name: dev
        match: |
          str::regex_matches(hypervisor("hypervisor_type"), "QEMU") &&
          str::regex_matches(hypervisor("hypervisor_hostname"), ".*node\\d{3}-bb(27\\d|096)")
      - name: clusterapi
        match: |
          str::regex_matches(hypervisor("hypervisor_type"), "QEMU") &&
          str::regex_matches(hypervisor("hypervisor_hostname"), ".*node\\d{3}-ap002")
    collectors:
      - name: agents
        type: agent
        hosts:
          secret:
            value: {{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/masakari/monitoring-agent/secret" {{"}}"}}
          mapping: str::regex_matches(hypervisor("hypervisor_hostname"), attribute("hostname"))
        listen: 0.0.0.0:{{ .Values.monitoringPort }}
        interval: 10
      - name: storage exporter
        type: prometheus
        interval: 30
        endpoint: http://prometheus-storage.infra-monitoring:9090
        metrics:
          - name: nfs idle time
            mapping: |
              str::contains(netbox_ip_address_by_interface("vmk0", "address", ""), attribute("client_ip")) ||
              hypervisor("host_ip") == attribute("client_ip")
            query:
              query: netapp_nfs_clients_idle_duration{volume="nova_001"}
    monitors:
      - name: nfs idle
        checks:
          - name: nfs
            collector: storage exporter
            metric: nfs idle time
            expected:
              - "<= 360.0"
      - name: heartbeat
        checks:
          - name: overall
            collector: agents
            metric: overall
            expected: good
          - name: overall
            collector: agents
            metric: elapsed
            expected: "<= 180.0"
      - name: nova
        checks:
          - name: hypervisor state
            hypervisor: state
            expected: up
      - name: ha
        any: false
        checks:
          - name: heartbeat
            monitor: heartbeat
          - name: nova
            monitor: nova
          - name: nfs idle
            monitor: nfs idle
        segments:
          - prod-blue
          - prod-green
          - dev
          - clusterapi
        notification:
          event: stopped
