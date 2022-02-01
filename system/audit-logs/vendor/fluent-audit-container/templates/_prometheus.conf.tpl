
# expose metrics in prometheus format
<source>
  @type prometheus
  bind 0.0.0.0
  port 24231
  metrics_path /metrics
</source>

<source>
    @type prometheus_monitor
    <labels>
        host ${hostname}
        node "#{ENV['K8S_NODE_NAME']}"
    </labels>
    interval 10
</source>

<source>
    @type prometheus_output_monitor
    <labels>
        host ${hostname}
        node "#{ENV['K8S_NODE_NAME']}"
    </labels>
    interval 10
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
      hostname ${hostname}
      node "#{ENV['K8S_NODE_NAME']}"
    </labels>
  </metric>
</filter>
