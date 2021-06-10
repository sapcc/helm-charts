http:
  host: "0.0.0.0"
pipeline:
  workers: {{.Values.logstashConfig.pipeline_workers | default 8 }}
  batch:
    size: {{.Values.logstashConfig.pipeline_batch_size | default 1500 }}