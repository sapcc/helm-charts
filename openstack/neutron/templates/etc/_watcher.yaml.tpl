custom_actions:
  networks:
    - method: GET
      action_type: read/list

    - network:
        - dhcp-agents:
            - method: GET
              action_type: read/list

  ports:
    - method: GET
      action_type: read/list

  segments:
    - method: GET
      action_type: read/list

  trunks:
    - method: GET
      action_type: read/list

  address-scopes:
    - method: GET
      action_type: read/list

  floatingips:
    - method: GET
      action_type: read/list

  routers:
    - method: GET
      action_type: read/list

    - router:
        - l3-agents:
            - method: GET
              action_type: read/list

  subnetpools:
    - method: GET
      action_type: read/list

  subnets:
    - method: GET
      action_type: read/list

  firewall_groups:
    - method: GET
      action_type: read/list

  firewall_policies:
    - method: GET
      action_type: read/list

  firewall_rules:
    - method: GET
      action_type: read/list

  rbac-policies:
    - method: GET
      action_type: read/list

  security-group-rules:
    - method: GET
      action_type: read/list

  security-groups:
    - method: GET
      action_type: read/list

  ikepolicies:
    - method: GET
      action_type: read/list

  ipsec-site-connections:
    - method: GET
      action_type: read/list

  endpoint-groups:
    - method: GET
      action_type: read/list

  vpnservices:
    - method: GET
      action_type: read/list

  flavors:
    - method: GET
      action_type: read/list

  service_profiles:
    - method: GET
      action_type: read/list

  metering:
    - metering-labels:
        - method: GET
          action_type: read/list

    - metering-label-rules:
        - method: GET
          action_type: read/list

  network-ip-availabilities:
    - method: GET
      action_type: read/list

  quotas:
    - method: GET
      action_type: read/list

  qos:
    - rule-types:
        - method: GET
          action_type: read/list

    - policies:
        - method: GET
          action_type: read/list

        - policy:
            - bandwidth_limit_rules:
                - method: GET
                  action_type: read/list

            - dscp_marking_rules:
                - method: GET
                  action_type: read/list

            - minimum_bandwidth_rules:
                - method: GET
                  action_type: read/list

  lbaas:
    - loadbalancers:
        - method: GET
          action_type: read/list

    - listeners:
        - method: GET
          action_type: read/list

    - pools:
        - method: GET
          action_type: read/list

        - pool:
            - members:
                - method: GET
                  action_type: read/list

    - healthmonitors:
        - method: GET
          action_type: read/list

  logging:
    - logging_resources:
        - method: GET
          action_type: read/list

        - logging_resource:
            - firewall_logs:
                - method: GET
                  action_type: read/list

  log:
    - logs:
        - method: GET
          action_type: read/list

    - loggable-resources:
        - method: GET
          action_type: read/list

  bgpvpn:
    - bgpvpns:
        - method: GET
          action_type: read/list

        - bgpvpn:
            - network_associations:
                - method: GET
                  action_type: read/list

            - router_associations:
                - method: GET
                  action_type: read/list

            - port_associations:
                - method: GET
                  action_type: read/list

  agents:
    - method: GET
      action_type: read/list

    - agent:
        - l3-routers:
            - method: GET
              action_type: read/list

    - dhcp-networks:
        - method: GET
          action_type: read/list
