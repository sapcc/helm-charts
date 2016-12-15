{{- define "pipeline_yaml_tpl" -}}
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
          - notifier://
          - file:///tmp/swift-meters.log?max_bytes=10000000&backup_count=5
{{- end -}}
