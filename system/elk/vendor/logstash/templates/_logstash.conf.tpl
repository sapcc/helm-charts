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
  if [type] == "syslog" { 
  
    # look for and, if found, decode syslog priority
    if [message] =~ "^<[0-9]{1,3}>" { 
      grok {
        patterns_dir => ["/elk-etc/syslog"]
        match => [ "message", "^<%{NONNEGINT:priority:int}>" ]
      }
      if [priority] <= 191 {
        # check for RFC 3164 vs RFC 5424
        if [message] =~ "^<[0-9]{1,3}>[0-9]{1,2} " {
          mutate {
            add_tag => ["syslog_rfc5424"]
          }
        }
        else {
	  mutate {
            add_tag =>  ["syslog_rfc3164"]
          }
        }
      }
      else {
        mutate {  
          add_tag => ["syslog_priority_invalid"]
        }
      }
    } 
    else {
      # only RFC 3164 allows a message to specify no priority
      mutate {  
	add_tag => [ "syslog_rfc3164", "syslog_priority_missing" ]
      }
    }
    # RFC 3164 suggests adding priority if it's missing. 
    # Even if missing, syslog_pri filter adds the default priority.
    syslog_pri {
      syslog_pri_field_name => "priority"
    }
    mutate {
      # follow convention used by logstash syslog input plugin
      rename => { "syslog_severity_code" => "severity" }
      rename => { "syslog_facility_code" => "facility" }
      rename => { "syslog_facility" => "facility_label" }
      rename => { "syslog_severity" => "severity_label" }
    }
    
    # parse both RFC 3164 and 5424
    grok {
      patterns_dir => "/elk-etc/syslog"
      match => [ "message", "%{SYSLOG}" ]
      tag_on_failure => [ "_grokparsefailure_syslog" ]
    }
    
    # Check if a timestamp source was found and work out elapsed time recieving log
    # Note, mutate filter will convert a date object to a string not in ISO8601 format, so rather use ruby filter
    ruby {
        code => "event['timestamp_logstash'] = event['@timestamp']"
    }
    if [timestamp_source] {
      date {
        locale => en
        # assume timezone for cases where it isn't provided
        timezone => "Africa/Johannesburg"
        match => [ "timestamp_source", "MMM d H:m:s", "MMM d H:m:s", "ISO8601" ]
      }
      # add a field for delta (in seconds) between logsource and logstash
      ruby {
        code => "event['time_elapsed_logstash'] = event['timestamp_logstash'] - event['@timestamp']"
      }
    }
    else {
      mutate {
	add_tag => ["syslog_timestamp_source_missing"]
      }
    }
    
    # Check if a host source was found
    if ! [host_source] {
      mutate {
	add_tag => ["syslog_host_source_missing"]
      }
    }
    
    # discard redundant info
    mutate {
      remove_field => [ "priority" ] #redundant and less useful once severity and facility are decoded
      replace => { "message" => "%{message_content}" } 
      remove_field => [ "message_syslog", "message_content" ] #already in content message
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
