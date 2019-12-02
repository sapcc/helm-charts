
# expose collator
<source>
  @type forward
  bind 0.0.0.0
  port 24224
</source>

# expose metrics in prometheus format
<source>
  @type prometheus
  bind 0.0.0.0
  port 24231
  metrics_path /metrics
</source>

<source>
    @id prometheus_monitor
    @type prometheus_monitor
    <labels>
        host ${hostname}
    </labels>
</source>

<source>
    @id prometheus_output_monitor
    @type prometheus_output_monitor
    <labels>
        host ${hostname}
    </labels>
</source>

<source>
    @id prometheus_tail_monitor
    @type prometheus_tail_monitor
    <labels>
        host ${hostname}
    </labels>
</source>

# metrics
# # count number of incoming records per tag
<filter kubernetes.**>
  @type prometheus
  <metric>
    name fluentd_input_status_num_records_total
    type counter
    desc The total number of incoming records
    <labels>
      tag ${tag}
      hostname ${hostname}
      nodename "#{ENV['K8S_NODE_NAME']}"
      container $.kubernetes.container_name
    </labels>
  </metric>
</filter>

# count number of outgoing records per tag
<match kubernetes.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name fluentd_output_status_num_records_total
      type counter
      desc The total number of outgoing records
      <labels>
        tag ${tag}
        hostname ${hostname}
        nodename "#{ENV['K8S_NODE_NAME']}"
        container $.kubernetes.container_name
      </labels>
    </metric>
  </store>
</match>

