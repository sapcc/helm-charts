service_type: 'compute/baremetal'
service_name: 'ironic'
prefix: '/v1'

# Ironic identifies every resource by `uuid`; only VIFs use `id`.
# Payloads are only kept for state changes; node, port and volume bodies
# can carry BMC and storage credentials.
resources:
  allocations:
    custom_id: uuid
    payloads:
      enabled: false
  chassis:
    custom_id: uuid
    payloads:
      enabled: false
  deploy_templates:
    custom_id: uuid
    payloads:
      enabled: false
  nodes:
    custom_id: uuid
    id_environ_key: ironic.node_idents
    payloads:
      enabled: false
    children:
      allocation:
        payloads:
          enabled: false
      validate:
        payloads:
          enabled: false
      maintenance:
        payloads:
          enabled: false
      management:
        singleton: true
        payloads:
          enabled: false
        children:
          indicators:
            payloads:
              enabled: false
      states:
        payloads:
          include:
            - target
        children:
          power:
            payloads:
              include:
                - target
      traits:
        payloads:
          enabled: false
      vifs:
        payloads:
          enabled: false
      vendor_passthru:
        singleton: true
        payloads:
          enabled: false
      vmedia:
        el_type_uri: compute/baremetal/node/vmedia
        payloads:
          enabled: false
  ports:
    custom_id: uuid
    payloads:
      enabled: false
  portgroups:
    custom_id: uuid
    payloads:
      enabled: false
  runbooks:
    custom_id: uuid
    payloads:
      enabled: false
  inspection_rules:
    custom_id: uuid
    payloads:
      enabled: false
  # driver names are not UUIDs, so /drivers/<name>/vendor_passthru still
  # falls through to an on-demand resource until the middleware fix lands
  drivers:
    payloads:
      enabled: false
  events:
    singleton: true
    payloads:
      enabled: false
  # 2025.2+: body is the full hardware inventory
  continue_inspection:
    singleton: true
    custom_id: uuid
    payloads:
      enabled: false
  # ironic-python-agent heartbeats carry the agent token
  heartbeat:
    el_type_uri: compute/baremetal/heartbeat
    payloads:
      enabled: false
  volume:
    singleton: true
    payloads:
      enabled: false
    children:
      connectors:
        custom_id: uuid
        payloads:
          enabled: false
      targets:
        custom_id: uuid
        payloads:
          enabled: false

