---
sources:
    - name: swift_meter_source
      interval: 300
      meters:
          - "storage.objects"
          - "storage.objects.size"
          - "storage.objects.containers"
          - "storage.containers.objects"
          - "storage.containers.objects.size"
          - "storage.objects.incoming.bytes"
          - "storage.objects.outgoing.bytes"
          - "storage.api.request"
      sinks:
          - swift_meter_sink
sinks:
    - name: swift_meter_sink
      transformers:
      publishers:
          - {{.Values.ceilometer_target | replace "://" "://_user_:_pass_@" | replace "_user_" .Values.ceilometer_target_username | replace "_pass_" .Values.ceilometer_target_password | replace "://:@" "://" }}?timeout={{.Values.ceilometer_timeout}}&verify_ssl={{.Values.ceilometer_verify_ssl}}{{if ne .Values.ceilometer_target_clientcert "" }}&clientcert={{.Values.ceilometer_target_clientcert}}{{if ne .Values.ceilometer_target_clientkey "" }}&clientkey={{.Values.ceilometer_target_clientkey}}{{end}}{{end}}
          - file:///tmp/swift-meters.log?max_bytes=10000000&backup_count=5
