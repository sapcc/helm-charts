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
  tcp {
    port  => {{.Values.input_syslog_port}}
    type => syslog
  }
  http {
    port  => {{.Values.input_alertmanager_port}}
    type => alert
  }
}

filter {
    if  [type] == "bigiplogs" {
           grok {
	       tag_on_failure => ["bigiplogs_grok_parse-failure", "grok"]
	       tag_on_timeout => ["_groktimeout"]
	       timeout_millis => [15000]
                   match => { "message" => "%{SYSLOG5424PRI}%{NONNEGINT:syslog_version} +(?:%{TIMESTAMP_ISO8601:timestamp}|-) +(?:%{HOSTNAME:host}|-) +(?:%{WORD:syslog_level}|-) +(?:%{WORD:syslog_proc}|-) +(?:%{WORD:syslog_msgid}|-) +(?:%{SYSLOG5424SD:syslog_sd}|-|) +%{GREEDYDATA:syslog_msg}" }
                   overwrite => [ "message" ]
                   }
           }
    if [type] == "alert" {
       json {
         source => "message"
       }
       if "_jsonparsefailure" not in [tags] {
         split {
           field => "alerts"
         }
         mutate {
             remove_field => ["message"]
         }
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
elseif [type] == "alert"{
  elasticsearch {
    index => "alerts-%{+YYYY}"
    template => "/elk-etc/alerts.json"
    template_name => "alerts"
    template_overwrite => true
    hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.cluster_region}}.{{.Values.global.domain}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
    user => "{{.Values.global.elk_elasticsearch_data_user}}"
    password => "{{.Values.global.elk_elasticsearch_data_password}}"
    ssl => true
  }
}
}
