input {
  udp {
    port  => {{.Values.input_netflow_port}}
    type => netflow
  }
  udp {
    port  => {{.Values.input_syslog_port}}
    type => syslog
  }
  udp {
    port  => {{.Values.input_bigiplogs_port}}
    type => bigiplogs
  }
  udp {
    port  => {{.Values.input_httplogs_port}}
    type => httplogs
  }
  tcp {
    port  => {{.Values.input_syslog_port}}
    type => syslog
  }
}

filter {
    # Manually parse the log, as we want to support both RCF3164 and RFC5424
    grok {
      break_on_match => true
      match => [ 
        "message", "%{SYSLOG5424LINE}",
        "message", "%{SYSLOGLINE}"
      ]
    }

    if [syslog5424_ts] {
      # Handle RFC5424 formatted Syslog messages
      mutate {
        remove_field => [ "message", "host" ]
        add_tag => [ "syslog5424" ]
      }
      mutate {
        # Use a friendlier naming scheme
        rename => { 
          "syslog5424_app"  => "program"
          "syslog5424_msg"  => "message"
          "syslog5424_host" => "host"
        }
        remove_field => [ "syslog5424_ver", "syslog5424_proc" ]
      }
      if [syslog5424_pri] {
        # Calculate facility and severity from the syslog PRI value
        ruby {
          code => "event['severity'] = event['syslog5424_pri'].modulo(8)"
        }
        ruby {
          code => "event['facility'] = (event['syslog5424_pri'] / 8).floor"
        }
        mutate {
          remove_field => [ "syslog5424_pri" ]
        }
      }
      if [syslog5424_sd] {
        # All structured data needs to be in format [key=value,key=value,...]
        mutate {
          # Remove wrapping brackets
          gsub => [ "syslog5424_sd", "[\[\]]", "" ]
        }
        kv {
          # Convert the structured data into Logstash fields
          source => "syslog5424_sd"
          field_split => ","
          value_split => "="
          remove_field => [ "syslog5424_sd" ]
        }
      }
      date {
        match => [ "syslog5424_ts", "ISO8601" ]
        remove_field => [ "syslog5424_ts", "timestamp" ]
      }
    }
    else {
      # Handle RFC3164 formatted Syslog messages
      mutate {
        add_tag => [ "syslog3164" ]
      }
    }
}

filter {
    if  [type] == "bigiplogs" {
           grok {
	       tag_on_failure => ["bigiplogs_grok_parse-failure", "grok"]
	       tag_on_timeout => ["_groktimeout"]
	       timeout_millis => [15000]
                   match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_severity} %{DATA:syslog_program}: %{GREEDYDATA:syslog_message}"
                   }
           }
           date {
             match => [ "syslog_timestamp", "MMM d HH:mm:ss", "MMM dd HH:mm:ss" ]
           }
    }
    if [type] == "httplogs" {
          grok {
	       tag_on_failure => ["httplogs_grok_parse-failure", "grok"]
	       tag_on_timeout => ["_groktimeout"]
	       timeout_millis => [15000]
            match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{IP:client_ip} %{NUMBER:client_port} %{IP:vitual_ip} %{NUMBER:virtual_port} %{DATA:http_version} %{IP:server_ip} %{NUMBER:server_port} %{NUMBER:http_status} %{NUMBER:response_time} %{NUMBER:bytes_received} %{URIPATH:uri_path} %{QUOTEDSTRING:agent} %{QUOTEDSTRING:referrer}"
            }
          }
          date {
            match => [ "syslog_timestamp", "MMM d HH:mm:ss", "MMM dd HH:mm:ss" ]
          }
    }
}

output {
if  [type] == "netflow" {
  elasticsearch {
    index => "netflow-%{+YYYY.MM.dd}"
    template => "/elk-etc/netflow.json"
    template_name => "netflow"
    template_overwrite => true
    hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.cluster_region}}.{{.Values.global.domain}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
    user => "{{.Values.global.elk_elasticsearch_data_user}}"
    password => "{{.Values.global.elk_elasticsearch_data_password}}"
    ssl => true 
  }
}
elseif [type] == "syslog" {
  elasticsearch {
    index => "syslog-%{+YYYY.MM.dd}"
    template => "/elk-etc/syslog.json"
    template_name => "syslog"
    template_overwrite => true
    hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.cluster_region}}.{{.Values.global.domain}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
    user => "{{.Values.global.elk_elasticsearch_data_user}}"
    password => "{{.Values.global.elk_elasticsearch_data_password}}"
    ssl => true 
  }
}
elseif [type] == "bigiplogs" {
  elasticsearch {
    index => "bigiplogs-%{+YYYY.MM.dd}"
    template => "/elk-etc/bigiplogs.json"
    template_name => "bigiplogs"
    template_overwrite => true
    hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.cluster_region}}.{{.Values.global.domain}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
    user => "{{.Values.global.elk_elasticsearch_data_user}}"
    password => "{{.Values.global.elk_elasticsearch_data_password}}"
    ssl => true 
  }
}
elseif [type] == "httplogs" {
  elasticsearch {
    index => "httplogs-%{+YYYY.MM.dd}"
    template => "/elk-etc/httplogs.json"
    template_name => "httplogs"
    template_overwrite => true
    hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.cluster_region}}.{{.Values.global.domain}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
    user => "{{.Values.global.elk_elasticsearch_data_user}}"
    password => "{{.Values.global.elk_elasticsearch_data_password}}"
    ssl => true 
  }
}
}
