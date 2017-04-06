input {
    kafka {
        bootstrap_servers => "kafka:{{.Values.monasca_kafka_port_internal}}"
        topics => ["transformed-log"]
        group_id => "logstash-metrics"
        client_id => "monasca_log_metrics"
        consumer_threads => 12
    }
}

filter {

  # drop logs that have not set log level
  if "level" not in [log] {
    drop { periodic_flush => true }
  } else {
    ruby {
      code => "
        log_level = event.get('[log][level]').downcase
        event.set('[log][level]', log_level)
      "
    }
  }

  # drop logs with log level not in warning,error
  if [log][level] not in [warning,error] {
    drop { periodic_flush => true }
  }

  ruby {
    code => "
      event.set('log_level', event.get('[log][level]').downcase)
      log_ts = Time.now.to_f * 1000.0

      # metric name
      metric_name = 'log.%s' % log_level

      # build metric
      metric = {}
      metric['name'] = metric_name
      metric['timestamp'] = log_ts
      metric['value'] = 1
      events.set(metric['dimensions'], event.get('[log][dimensions]'))
      metric['value_meta'] = {}

      event.set('[metric]', metric.to_hash)
    "
  }

  mutate {
    remove_field => ["log", "@version", "@timestamp", "log_level_original", "tags"]
  }

}

output {
    kafka {
        bootstrap_servers => "kafka:{{.Values.monasca_kafka_port_internal}}"
        topic_id => "metrics"
        client_id => "monasca_log_metrics"
        compression_type => "none"
        reconnect_backoff_ms => 1000
        retries => 10
        retry_backoff_ms => 1000
    }
}
