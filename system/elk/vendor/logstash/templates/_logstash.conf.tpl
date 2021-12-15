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
    codec => plain
  }
  tcp {
    port  => {{.Values.input_deployments_port}}
    type => deployment
    codec => plain
  }
{{- if .Values.tls.enabled }}
  http {
    port  => {{.Values.input_http_port}}
    type => awx
    user => '{{.Values.global.elk_elasticsearch_awx_user}}'
    password => '{{.Values.global.elk_elasticsearch_awx_password}}'
    ssl => true
    ssl_certificate => '/tls-secret/tls.crt'
    ssl_key => '/usr/share/logstash/config/tls.key'
  }
{{- end}}
}

filter {
  if  [type] == "syslog" {
    mutate {
      replace => { "host" => "[host][ip]"}
      copy => { "[host][ip]" => "[host][name]"}
    }

    dns {
      reverse => [ "[host][name]" ]
      action => "replace"
      hit_cache_size => "100"
      hit_cache_ttl => "2678600"
      failed_cache_size => "100"
      failed_cache_ttl => "3600"
    }
  }
    if  [type] == "bigiplogs" {
           grok {
         tag_on_failure => ["bigiplogs_grok_parse-failure", "grok"]
         tag_on_timeout => ["_groktimeout"]
         timeout_millis => [15000]
                   match => { "message" => "%{SYSLOG5424PRI}%{NONNEGINT:syslog_version} +(?:%{TIMESTAMP_ISO8601:timestamp}|-) +(?:%{HOSTNAME:syslog_host}|-) +(?:%{WORD:syslog_level}|-) +(?:%{WORD:syslog_proc}|-) +(?:%{WORD:syslog_msgid}|-) +(?:%{SYSLOG5424SD:syslog_sd}|-|) +%{GREEDYDATA:syslog_msg}" }
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
    if [type] == "deployment" {
       json {
         source => "message"
       }
       if "_jsonparsefailure" not in [tags] {
         split {
           field => "helm-release"
         }
         mutate {
             remove_field => ["message"]
         }
       }
    }
{{- if .Values.tls.enabled }}
    if [type] == "awx" {
       json {
         source => "message"
       }
    }
{{- end}}
  }


output {
  if  [type] == "netflow" {
    elasticsearch {
      index => "netflow-%{+YYYY.MM.dd}"
      template => "/elk-etc/netflow.json"
      template_name => "netflow"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.elk_cluster_region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
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
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.elk_cluster_region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
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
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.elk_cluster_region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif [type] == "alert" and [alerts][labels][severity] == "critical"{
    elasticsearch {
      index => "alerts-critical-%{+YYYY}"
      template => "/elk-etc/alerts.json"
      template_name => "alerts"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.elk_cluster_region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif [type] == "alert" and [alerts][labels][severity] == "warning"{
      elasticsearch {
        index => "alerts-warning-%{+YYYY}"
        template => "/elk-etc/alerts.json"
        template_name => "alerts"
        template_overwrite => true
        hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.elk_cluster_region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
        user => "{{.Values.global.elk_elasticsearch_data_user}}"
        password => "{{.Values.global.elk_elasticsearch_data_password}}"
        ssl => true
    }
  }
  elseif [type] == "alert"{
    elasticsearch {
      index => "alerts-other-%{+YYYY}"
      template => "/elk-etc/alerts.json"
      template_name => "alerts"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.elk_cluster_region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif [type] == "deployment" {
    elasticsearch {
      index => "deployments-%{+YYYY}"
      template => "/elk-etc/deployments.json"
      template_name => "deployments"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.elk_cluster_region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
{{- if .Values.tls.enabled }}
  elseif [type] == "awx" {
    elasticsearch {
      index => "deployments-%{+YYYY}"
      template => "/elk-etc/deployments.json"
      template_name => "deployments"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.elk_cluster_region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
{{- end}}
}
