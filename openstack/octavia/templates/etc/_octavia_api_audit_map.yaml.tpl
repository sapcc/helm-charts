service_type: loadbalancer
service_name: octavia
prefix: '/v2(\.0)?'

resources:
  lbaas:
    singleton: true
    children:
      healthmonitors:
        type_uri: network/loadbalancer/healthmonitors
      loadbalancers:
        type_uri: network/loadbalancers
        children:
          stats:
            singleton: true
          status:
            singleton: true
          failover:
            singleton: true
      listeners:
        type_uri: network/loadbalancer/listeners
        children:
          stats:
            singleton: true
      pools:
        type_uri: network/loadbalancer/pools
        children:
          members:
      l7policies:
        type_uri: network/loadbalancer/l7policies
        el_type_uri: network/loadbalancer/l7policy
        children:
          rules:
      quotas:
        type_uri: network/loadbalancer/quotas
        children:
          defaults:
            singleton: true
      flavors:
        type_uri: network/loadbalancer/flavors
      flavorprofiles:
        type_uri: network/loadbalancer/flavorprofiles
      availabilityzoneprofiles:
        type_uri: network/loadbalancer/availabilityzoneprofiles
      providers:
        type_uri: network/loadbalancer/providers
        children:
          flavor_capabilities:
            singleton: true
          availability_zone_capabilities:
            singleton: true

  octavia:
    singleton: true
    children:
      amphorae:
        type_uri: network/loadbalancer/amphorae
        children:
          stats:
            singleton: true
          config:
            singleton: true
          failover:
            singleton: true

