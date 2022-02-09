http:
  host: "0.0.0.0"
pipeline:
  workers: {{.Values.logstashConfig.pipeline_workers }}
  batch:
    size: {{.Values.logstashConfig.pipeline_batch_size }}
