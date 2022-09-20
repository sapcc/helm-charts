input {
  udp {
    port  => {{.Values.input_syslog_port}}
    type => syslog
  }
  tcp {
    port  => {{.Values.input_syslog_port}}
    type => syslog
  }
  udp {
    port  => {{.Values.input_netflow_port}}
    type => netflow
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
  http {
    port  => {{.Values.input_http_port}}
    user => '{{.Values.global.elk_elasticsearch_http_user}}'
    password => '{{.Values.global.elk_elasticsearch_http_password}}'
    ssl => true
    ssl_certificate => '/tls-secret/tls.crt'
    ssl_key => '/usr/share/logstash/config/tls.key'
  }
}

filter {
 if  [type] == "syslog" {
   mutate {
     copy => { "host" => "hostname"}
   }

   dns {
     reverse => [ "hostname" ]
     action => "replace"
     hit_cache_size => "100"
     hit_cache_ttl => "2678600"
     failed_cache_size => "100"
     failed_cache_ttl => "3600"
   }
    grok {
      match => {
        "message" => [
                      "<%{NONNEGINT:syslog_pri}>: %{SYSLOGCISCOTIMESTAMP:syslog_timestamp}: %{SYSLOGCISCOSTRING}: %{GREEDYDATA:syslog_message}",
                      "<%{NONNEGINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{SYSLOGPROG:syslog_process}: %{SYSLOGCISCOSTRING}: %{GREEDYDATA:syslog_message}",
                      "<%{NONNEGINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} Severity: (?<syslog_severity>\w+), Category: (?<syslog_category>\w+), MessageID: (?<syslog_messageid>\w+), Message: %{GREEDYDATA:syslog_message}",
                      "<%{NONNEGINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{SYSLOGPROG:syslog_process}: %{GREEDYDATA:syslog_message}",
                      "<%{NONNEGINT:syslog_pri}>%{PROG:syslog_process}\[%{POSINT:pid}\]: %{GREEDYDATA:syslog_message}",
                      "<%{NONNEGINT:syslog_pri}>Severity: (?<syslog_severity>\w+), Category: (?<syslog_category>\w+), MessageID: (?<syslog_messageid>\w+), Message: %{GREEDYDATA:syslog_message}",
                      "<%{NONNEGINT:syslog_pri}>%{GREEDYDATA:syslog_message}"
                      ]
                }
      break_on_match => "true"
      overwrite => ["message"]
      patterns_dir => ["/logstash-etc/*.grok"]
      tag_on_failure => ["_syslog_grok_failure"]
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
  }


output {
  if [type] == "syslog" {
    elasticsearch {
      index => "syslog-%{+YYYY.MM.dd}"
      template => "/logstash-etc/syslog.json"
      template_name => "syslog"
      template_overwrite => true
      data_stream => false
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif [type] == "alert" and [alerts][labels][severity] == "critical"{
    elasticsearch {
      index => "alerts-critical-%{+YYYY}"
      template => "/logstash-etc/alerts.json"
      template_name => "alerts"
      template_overwrite => true
      data_stream => false
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif [type] == "alert" and [alerts][labels][severity] == "warning"{
      elasticsearch {
        index => "alerts-warning-%{+YYYY}"
        template => "/logstash-etc/alerts.json"
        template_name => "alerts"
        template_overwrite => true
        data_stream => false
        hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
        user => "{{.Values.global.elk_elasticsearch_data_user}}"
        password => "{{.Values.global.elk_elasticsearch_data_password}}"
        ssl => true
    }
  }
  elseif [type] == "alert"{
    elasticsearch {
      index => "alerts-other-%{+YYYY}"
      template => "/logstash-etc/alerts.json"
      template_name => "alerts"
      template_overwrite => true
      data_stream => false
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif [type] == "deployment" {
    elasticsearch {
      index => "deployments-%{+YYYY}"
      template => "/logstash-etc/deployments.json"
      template_name => "deployments"
      template_overwrite => true
      data_stream => false
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif  [type] == "netflow" {
    elasticsearch {
      index => "netflow-%{+YYYY.MM.dd}"
      template => "/logstash-etc/netflow.json"
      template_name => "netflow"
      template_overwrite => true
      data_stream => false
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
}
