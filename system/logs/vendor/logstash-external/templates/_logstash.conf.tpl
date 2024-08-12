input {
  udp {
    id => "input-udp-syslog"
    port  => {{.Values.input.syslog_port}}
    type => syslog
  }
  tcp {
    id => "input-tcp-syslog"
    port  => {{.Values.input.syslog_port}}
    type => syslog
  }
  udp {
    id => "input-udp-netflow"
    port  => {{.Values.input.netflow_port}}
    type => netflow
  }
  http {
    id => "input-http"
    port  => {{.Values.input.alertmanager_port}}
    type => alert
    codec => plain
  }
  tcp {
    id => "input-tcp"
    port  => {{.Values.input.deployments_port}}
    type => deployment
    codec => plain
  }
  http {
    id => "input-http-secure"
    port  => {{.Values.input.http_port}}
    user => "${HTTP_USER}"
    password => "${HTTP_PASSWORD}"
    ssl_enabled => true
    ssl_certificate => '/tls-secret/tls.crt'
    ssl_key => '/usr/share/logstash/config/tls.key'
  }
  beats {
    id => "input-beats"
    port => {{.Values.input.beats_port}}
    type => "jumpserver"
  }
}

filter {
 if  [type] == "syslog" {
   mutate {
     id => "syslog-rename-hostname"
     rename => { "host" => "hostname"}
   }

   dns {
     id => "syslog-dns-resolve"
     reverse => [ "hostname" ]
     action => "replace"
     hit_cache_size => "100"
     hit_cache_ttl => "2678600"
     failed_cache_size => "100"
     failed_cache_ttl => "3600"
   }
    grok {
      id => "syslog-grok"
      match => {
        "message" => [
                      "<%{NONNEGINT:syslog_pri}>: %{SYSLOGCISCOTIMESTAMP:syslog_timestamp}: %{SYSLOGCISCOSTRING}:",
                      "<%{NONNEGINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{SYSLOGPROG:syslog_process}: %{SYSLOGCISCOSTRING}:",
                      "<%{NONNEGINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} Severity: (?<syslog_severity>\w+), Category: (?<syslog_category>\w+), MessageID: (?<syslog_messageid>\w+)",
                      "<%{NONNEGINT:syslog_pri}>%{PROG:syslog_process}\[%{POSINT:pid}\]",
                      "<%{NONNEGINT:syslog_pri}>Severity: (?<syslog_severity>\w+), Category: (?<syslog_category>\w+), MessageID: (?<syslog_messageid>\w+)"
                      ]
                }
      break_on_match => "true"
      overwrite => ["message"]
      patterns_dir => ["/logstash-etc/*.grok"]
      tag_on_failure => ["_syslog_grok_failure"]
    }
  }

  if  [type] == "jumpserver" {
    mutate {
        id => "jump-split"
        split => { "[host][hostname]" => "-" }
        add_field => { "fqdn" => "%{[host][hostname][0]}.cc.%{[host][hostname][1]}-%{[host][hostname][2]}-%{[host][hostname][3]}.cloud.sap" }
        remove_field => "[host][hostname]"
    }
  }

  if [type] == "alert" {
     json {
       id => "alert-json-decode"
       source => "message"
     }
     if "_jsonparsefailure" not in [tags] {
       split {
         id => "alert-json-split"
         field => "alerts"
       }
       mutate {
           id => "alert-remove-message"
           remove_field => ["message"]
       }
     }
  }
    if [type] == "deployment" {
       json {
         id => "deployment-json-decode"
         source => "message"
       }
       if "_jsonparsefailure" not in [tags] {
         split {
           id => "deployment-json-split"
           field => "helm-release"
         }
         mutate {
             id => "deployment-remove-message"
             remove_field => ["message"]
         }
       }
    }
  }


output {
  if [type] == "syslog" {
    opensearch {
      id => "opensearch-syslog"
      index => "syslog-%{+YYYY.MM.dd}"
      hosts => ["https://{{.Values.global.opensearch.host}}:{{.Values.global.opensearch.port}}"]
      template => "/logstash-etc/syslog.json"
      template_name => "syslog"
      template_overwrite => true
      auth_type => {
        type => "basic"
        user => "${OPENSEARCH_SYSLOG_USER}"
        password => "${OPENSEARCH_SYSLOG_PASSWORD}"
      }
      ssl => true
      ssl_certificate_verification => true
    }
  }
  elseif [type] == "alert" and [alerts][labels][severity] == "critical"{
    opensearch {
      id => "opensearch-critical-alerts"
      index => "alerts-critical-%{+YYYY}"
      hosts => ["https://{{.Values.global.opensearch.host}}:{{.Values.global.opensearch.port}}"]
      auth_type => {
        type => "basic"
        user => "${OPENSEARCH_SYSLOG_USER}"
        password => "${OPENSEARCH_SYSLOG_PASSWORD}"
      }
      template => "/logstash-etc/alerts.json"
      template_name => "alerts"
      template_overwrite => true
      ssl => true
      ssl_certificate_verification => true
    }
  }
  elseif [type] == "alert" and [alerts][labels][severity] == "warning"{
    opensearch {
      id => "opensearch-warnings"
      index => "alerts-warnings-%{+YYYY}"
      hosts => ["https://{{.Values.global.opensearch.host}}:{{.Values.global.opensearch.port}}"]
      auth_type => {
        type => "basic"
        user => "${OPENSEARCH_SYSLOG_USER}"
        password => "${OPENSEARCH_SYSLOG_PASSWORD}"
      }
      template => "/logstash-etc/alerts.json"
      template_name => "alerts"
      template_overwrite => true
      ssl => true
      ssl_certificate_verification => true
    }
  }
  elseif [type] == "alert"{
    opensearch {
      id => "opensearch-alerts"
      index => "alerts-other-%{+YYYY}"
      hosts => ["https://{{.Values.global.opensearch.host}}:{{.Values.global.opensearch.port}}"]
      auth_type => {
        type => "basic"
        user => "${OPENSEARCH_SYSLOG_USER}"
        password => "${OPENSEARCH_SYSLOG_PASSWORD}"
      }
      template => "/logstash-etc/alerts.json"
      template_name => "alerts"
      template_overwrite => true
      ssl => true
      ssl_certificate_verification => true
    }
  }
  elseif [type] == "deployment" {
    opensearch {
      id => "opensearch-deployments"
      index => "deployments-%{+YYYY}"
      hosts => ["https://{{.Values.global.opensearch.host}}:{{.Values.global.opensearch.port}}"]
      auth_type => {
        type => "basic"
        user => "${OPENSEARCH_SYSLOG_USER}"
        password => "${OPENSEARCH_SYSLOG_PASSWORD}"
      }
      template => "/logstash-etc/deployments.json"
      template_name => "deployments"
      template_overwrite => true
      ssl => true
      ssl_certificate_verification => true
    }
  }
  elseif  [type] == "netflow" {
    opensearch {
      id => "opensearch-netflow"
      index => "netflow-%{+YYYY.MM.dd}"
      hosts => ["https://{{.Values.global.opensearch.host}}:{{.Values.global.opensearch.port}}"]
      auth_type => {
        type => 'basic'
        user => "${OPENSEARCH_USER}"
        password => "${OPENSEARCH_PASSWORD}"
      }
      ssl => true
      ssl_certificate_verification => true
    }
  }
  elseif  [type] == "jumpserver" {
    opensearch {
      id => "opensearch-jump"
      index => "jump-%{+YYYY.MM.dd}"
      hosts => ["https://{{.Values.global.opensearch.host}}:{{.Values.global.opensearch.port}}"]
      auth_type => {
        type => 'basic'
        user => "${OPENSEARCH_JUMP_USER}"
        password => "${OPENSEARCH_JUMP_PASSWORD}"
      }
      ssl => true
      ssl_certificate_verification => true
    }
  }
}
