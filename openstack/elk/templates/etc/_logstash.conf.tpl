input {
  udp {
    port  => {{.Values.elk_logstash_input_netflow_port}}
    type => netflow
  }
  udp {
    port  => {{.Values.elk_logstash_input_syslog_port}}
    type => syslog
  }
  tcp {
    port  => {{.Values.elk_logstash_input_syslog_port}}
    type => syslog
  }
}


output {
{{- if .Values.controlplane.enabled }}
if  [type] == "netflow" {
  elasticsearch {
    index => "netflow-%{+YYYY.MM.dd}"
    template => "/elk-etc/netflow.json"
    template_name => "netflow"
    template_overwrite => true
    hosts => ["{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_http_port}}"]
    user => "{{.Values.elk_elasticsearch_data_user}}"
    password => "{{.Values.elk_elasticsearch_data_password}}"
  }
}
elseif [type] == "syslog" {
  elasticsearch {
    index => "syslog-%{+YYYY.MM.dd}"
    template => "/elk-etc/syslog.json"
    template_name => "syslog"
    template_overwrite => true
    hosts => ["{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_http_port}}"]
    user => "{{.Values.elk_elasticsearch_data_user}}"
    password => "{{.Values.elk_elasticsearch_data_password}}"
  }
}
{{ end -}}
{{- if .Values.scaleout.enabled }}
if  [type] == "netflow" {
  elasticsearch {
    index => "netflow-%{+YYYY.MM.dd}"
    template => "/elk-etc/netflow.json"
    template_name => "netflow"
    template_overwrite => true
    hosts => ["{{.Values.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.cluster_region}}.{{.Values.domain}}:{{.Values.elk_elasticsearch_ssl_port}}"]
    user => "{{.Values.elk_elasticsearch_data_user}}"
    password => "{{.Values.elk_elasticsearch_data_password}}"
    ssl => true 
  }
}
elseif [type] == "syslog" {
  elasticsearch {
    index => "syslog-%{+YYYY.MM.dd}"
    template => "/elk-etc/syslog.json"
    template_name => "syslog"
    template_overwrite => true
    hosts => ["{{.Values.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.cluster_region}}.{{.Values.domain}}:{{.Values.elk_elasticsearch_ssl_port}}"]
    user => "{{.Values.elk_elasticsearch_data_user}}"
    password => "{{.Values.elk_elasticsearch_data_password}}"
    ssl => true 
  }
}
{{ end -}}
}
