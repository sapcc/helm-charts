http:
  host: "0.0.0.0"
pipeline:
  workers: {{.Values.logstashConfig.pipeline_workers | default 5 }}
  batch:
    size: {{.Values.logstashConfig.pipeline_batch_size | default 750 }}