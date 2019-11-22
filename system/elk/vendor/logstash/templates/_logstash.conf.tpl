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
  udp {
    port  => {{.Values.input_ddoslogs_port}}
    type => ddoslogs
  }
  tcp {
    port  => {{.Values.input_syslog_port}}
    type => syslog
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
    if [type] == "ddoslogs" {
          grok {
	       tag_on_failure => ["ddoslogs_grok_parse-failure", "grok"]
	       tag_on_timeout => ["_groktimeout"]
	       timeout_millis => [15000]
		  match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} action=\"%{WORD:action}\",hostname=\"%{DATA:f5_hostname}\",bigip_mgmt_ip=\"%{DATA:mgmt_ip}\",context_name=\"%{DATA:context}\",date_time=\"%{DATA:attack_time}\",dest_ip=\"%{DATA:dest_ip}\",dest_port=\"%{DATA:dest_port}\",device_product=\"Advanced Module\",device_vendor=\"F5\",device_version=\"(.*?)\",dos_attack_event=\"%{DATA:dos_attack_event}\",dos_attack_id=\"%{NUMBER:dos_attack_id}\",dos_attack_name=\"%{DATA:dos_attack_name}\",dos_packets_dropped=\"%{INT:packets_dropped}\",dos_packets_received=\"%{INT:packets_received}\",errdefs_msgno=\"(.*?)\",errdefs_msg_name=\"(.*?)\",flow_id=\"(.*?)\",severity=\"%{INT:severity}\",partition_name=\"%{DATA:partition_name}\",route_domain=\"%{DATA:route_domain}\",source_ip=\"%{DATA:source_ip}\",source_port=\"%{DATA:source_port}\",vlan=\"%{DATA:vlan}\""
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
    index => "syslog-%{+YYYY.MM.dd}"
    template => "/elk-etc/httplogs.json"
    template_name => "httplogs"
    template_overwrite => true
    hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.cluster_region}}.{{.Values.global.domain}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
    user => "{{.Values.global.elk_elasticsearch_data_user}}"
    password => "{{.Values.global.elk_elasticsearch_data_password}}"
    ssl => true 
  }
}
elseif [type] == "ddoslogs" {
  elasticsearch {
    index => "ddoslogs-%{+YYYY.MM.dd}"
    template => "/elk-etc/ddoslogs.json"
    template_name => "ddoslogs"
    template_overwrite => true
    hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.cluster_region}}.{{.Values.global.domain}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
    user => "{{.Values.global.elk_elasticsearch_data_user}}"
    password => "{{.Values.global.elk_elasticsearch_data_password}}"
    ssl => true 
  }
}
}
