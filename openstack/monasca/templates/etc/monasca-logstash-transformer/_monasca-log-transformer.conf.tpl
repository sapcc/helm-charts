{{- define "monasca_logstash_transformer_monasca_log_transformer_conf_tpl" -}}
input {
    kafka {
        zk_connect => "zk:{{.Values.monasca_zookeeper_port_internal}}"
        topic_id => "log"
        group_id => "logstash-transformer"
    }
}

filter {
    ruby {
      code => "event['message_tmp'] = event['log']['message'][0..49]"
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
            if event['log_level']
                # keep original value
                log_level = event['log_level'].downcase
                if LOG_LEVELS_MAP.has_key?(log_level)
                    event['log_level_original'] = event['log_level']
                    event['log_level'] = LOG_LEVELS_MAP[log_level]
                else
                    event['log_level'] = log_level.capitalize
                end
            else
                event['log_level'] = 'Unknown'
            end
        "
    }

    mutate {
        add_field => {
            "[log][level]" => "%{log_level}"
        }

        # remove temporary fields
        remove_field => ["log_level", "message_tmp"]
    }
}

output {
    kafka {
        bootstrap_servers => "kafka:{{.Values.monasca_kafka_port_internal}}"
        topic_id => "transformed-log"
    }
}
{{ end }}
