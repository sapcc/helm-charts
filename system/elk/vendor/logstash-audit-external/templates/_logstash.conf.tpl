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
  http {
    port  => {{.Values.input_http_port}}
    type => audit
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
                      "<%{NONNEGINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{SYSLOGPROG:syslog_process}: %{GREEDYDATA:syslog_message}",
                      "<%{NONNEGINT:syslog_pri}>%{PROG:syslog_process}\[%{POSINT:pid}\]: %{GREEDYDATA:syslog_message}",
                      "<%{NONNEGINT:syslog_pri}>%{GREEDYDATA:syslog_message}"
                      ]
                }
      break_on_match => "true"
      overwrite => ["message"]
      patterns_dir => ["/elk-etc/*.grok"]
      tag_on_failure => ["_syslog_grok_failure"]
    }

# Change type of audit relevant UCSM syslogs to "audit"
  if [syslogcisco_facility] {
    if [syslogcisco_facility] == "%UCSM"  and [syslogcisco_code] == "AUDIT" {
      mutate {
        replace => { "type" => "audit" }
      }
    }
  }

# Change type of audit relevant HSM syslogs
  if [syslog_hostname] and [syslog_hostname] == "hsm01" {
    mutate {
        replace => { "type" => "audit" }
      }
  }

 }
    if  [type] == "bigiplogs" {
           grok {
         tag_on_failure => ["bigiplogs_grok_parse-failure", "grok"]
         tag_on_timeout => ["_groktimeout"]
         patterns_dir => ["/elk-etc/*.grok"]
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
    if [type] == "audit"{
      clone {
        clones => ['octobus', 'elk']
      }
    }
  }


output {
  if [type] == "elk" {
    elasticsearch {
      index => "audit-%{+YYYY.MM.dd}"
      template => "/elk-etc/audit.json"
      template_name => "audit"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.elk_cluster_region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_audit_user}}"
      password => "{{.Values.global.elk_elasticsearch_audit_password}}"
      ssl => true
    }
  }
  elseif [type] == "octobus" {
    http {
      cacert => "/usr/share/logstash/config/ca.pem"
      url => "https://{{ .Values.forwarding.audit.host }}"
      format => "json"
      http_method => "post"
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
  elseif  [type] == "netflow" {
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
}
