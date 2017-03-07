---
sources:
    - name: billing_source
      events:
          - "objectstore.http.request"
          - "identity.user.*"
          - "identity.project.*"
      sinks:
          - billing_sink
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
    - name: billing_sink
      transformers:
      triggers:
      publishers:
          - {{.Values.ceilometer_event_target | replace "://" "://_user_:_pass_@" | replace "_user_" .Values.ceilometer_event_target_username | replace "_pass_" .Values.ceilometer_event_target_password | replace "://:@" "://" }}?timeout={{.Values.ceilometer_timeout}}&verify_ssl={{.Values.ceilometer_verify_ssl}}{{if ne .Values.ceilometer_event_target_clientcert "" }}&clientcert={{.Values.ceilometer_event_target_clientcert}}{{if ne .Values.ceilometer_event_target_clientkey "" }}&clientkey={{.Values.ceilometer_event_target_clientkey}}{{end}}{{end}}
    - name: audit_sink
      transformers:
      triggers:
      publishers:
          - kafka://{{.Values.monasca_kafka_hostname}}:{{.Values.monasca_kafka_port_internal}}?topic=events-cadf
