---
sources:
    - name: event_source
      interval: 300
      events:
          - "objectstore.http.request"
          - "identity.user.*"
          - "identity.project.*"
      sinks:
          - event_sink
sinks:
    - name: event_sink
      transformers:
      triggers:
      publishers:
          - notifier://
