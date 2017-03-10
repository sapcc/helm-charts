input {
    kafka {
        bootstrap_servers => "kafka:{{.Values.monasca_kafka_port_internal}}"
        topics => ["log"]
        group_id => "logstash-transformer"
        client_id => "monasca_log_transformer"
        consumer_threads => 12
        }
}

filter {

    ruby {
      code => "event.set('message_tmp', event.get('[log][message][0..49]'))"
    }
    grok {
        match => {
            "[message_tmp]" => "(?i)(?<log_level>AUDIT|CRITICAL|DEBUG|INFO|TRACE|ERR(OR)?|WARN(ING)?)|\"level\":\s?(?<log_level>\d{2})"
            add_tag => [ "log_level" ]
        }
    }
    if ! [log_level] {
        grok {
            match => {
                "[log][message]" => "(?i)(?<log_level>AUDIT|CRITICAL|DEBUG|INFO|TRACE|ERR(OR)?|WARN(ING)?)|\"level\":\s?(?<log_level>\d{2})"
                add_tag => [ "no_log_level" ]
            }
        }
    }
    ruby {
        init => "
            LOG_LEVELS_MAP = {
              # SYSLOG
              'warn' => :Warning,
              'err' => :Error,
              # Bunyan errcodes
              '10' => :Trace,
              '20' => :Debug,
              '30' => :Info,
              '40' => :Warning,
              '50' => :Error,
              '60' => :Fatal
            }
        "
        code => "
            if event.get('log_level')
                # keep original value
                event.set('log_level', event.get('[log_level]').downcase)
                if LOG_LEVELS_MAP.has_key?(log_level)
                    event.set('log_level_original', event.get('[log_level]'))
                    event.set('log_level', LOG_LEVELS_MAP[log_level])
                else
                    event.set('log_level', log_level.capitalize)
                end
            else
                event.set('log_level', 'Unknown')
            end
        "
    }

    mutate {
        add_field => {
            "[log][level]" => "%{log_level}"
        }

        # remove temporary fields
        remove_field => ["message_tmp"]
    }
}

output {
    kafka {
        bootstrap_servers => "kafka:{{.Values.monasca_kafka_port_internal}}"
        topic_id => "transformed-log"
        reconnect_backoff_ms => 1000
        retries => 10
        retry_backoff_ms => 1000
        codec => json
        }
}
