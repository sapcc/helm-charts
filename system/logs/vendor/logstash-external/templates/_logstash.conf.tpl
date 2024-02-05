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
  beats {
    port => {{.Values.input_beats_port}}
    id => "beats"
    type => "jumpserver"
  }
}

filter {
 if  [type] == "syslog" {
   mutate {
     rename => { "host" => "hostname"}
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
    opensearch {
      id => "opensearch-syslog"
      index => "syslog-%{+YYYY.MM.dd}"
      hosts => ["https://{{.Values.opensearch.http.endpoint}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.opensearch.http_port}}"]
      template => "/logstash-etc/syslog.json"
      template_name => "syslog"
      template_overwrite => true
      auth_type => {
        type => "basic"
        user => "${OPENSEARCH_USER}"
        password => "${OPENSEARCH_PASSWORD}"
      }
      ssl => true
      ssl_certificate_verification => true
    }
  }
  elseif [type] == "alert" and [alerts][labels][severity] == "critical"{
    opensearch {
      id => "opensearch-critical-alerts"
      index => "alerts-critical-%{+YYYY}"
      hosts => ["https://{{.Values.opensearch.http.endpoint}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.opensearch.http_port}}"]
      auth_type => {
        type => "basic"
        user => "${OPENSEARCH_USER}"
        password => "${OPENSEARCH_PASSWORD}"
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
      hosts => ["https://{{.Values.opensearch.http.endpoint}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.opensearch.http_port}}"]
      auth_type => {
        type => "basic"
        user => "${OPENSEARCH_USER}"
        password => "${OPENSEARCH_PASSWORD}"
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
      hosts => ["https://{{.Values.opensearch.http.endpoint}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.opensearch.http_port}}"]
      auth_type => {
        type => "basic"
        user => "${OPENSEARCH_USER}"
        password => "${OPENSEARCH_PASSWORD}"
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
      hosts => ["https://{{.Values.opensearch.http.endpoint}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.opensearch.http_port}}"]
      auth_type => {
        type => "basic"
        user => "${OPENSEARCH_USER}"
        password => "${OPENSEARCH_PASSWORD}"
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
      hosts => ["https://{{.Values.opensearch.http.endpoint}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.opensearch.http_port}}"]
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
      hosts => ["https://{{.Values.opensearch.http.endpoint}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.opensearch.http_port}}"]
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
