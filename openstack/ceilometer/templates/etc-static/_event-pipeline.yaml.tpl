---
sources:
    - name: event_source
      events:
          - "objectstore.http.request"
          - "identity.user.*"
          - "identity.project.*"
      sinks:
          - event_sink
    - name: audit_source
      events:
          - "identity.user.*"
          - "identity.project.*"
          - "identity.group.*"
          - "identity.role.*"
          - "identity.OS-TRUST:trust.*"
          - "identity.region.*"
          - "identity.service.*"
          - "identity.endpoint.*"
          - "identity.policy.*"
          - "identity.role_assignment.*"
          - "compute.instance.*"
          - "volume.*"
          - "snapshot.*"
          - "image.*"
          - "orchestration.*"
          - "sahara.*"
          - "network.*"
          - "subnet.*"
          - "port.*"
          - "router.*"
          - "floatingip.*"
          - "pool.*"
          - "vip.*"
          - "member.*"
          - "health_monitor.*"
          - "firewall.*"
          - "firewall_policy.*"
          - "firewall_rule.*"
          - "vpnservice.*"
          - "ipsecpolicy.*"
          - "ikepolicy.*"
          - "ipsec_site_connection.*"
          - "dns.domain.*"
          - "trove.instance.*"
      sinks:
          - audit_sink
sinks:
    - name: event_sink
      transformers:
      triggers:
      publishers:
          - notifier://
    - name: audit_sink
      transformers:
      triggers:
      publishers:
          - kafka://{{.Values.monasca_kafka_hostname}}:{{.Values.monasca_kafka_port_internal}}?topic=events-cadf
