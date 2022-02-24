input {
{{- if .Values.syslog.enabled }}
  udp {
    port  => {{.Values.input_syslog_port}}
    type => syslog
  }
  tcp {
    port  => {{.Values.input_syslog_port}}
    type => syslog
  }
{{- end }}
{{- if eq .Values.global.clusterType "metal" }}
  udp {
    port  => {{.Values.input_netflow_port}}
    type => netflow
  }
  udp {
    port  => {{.Values.input_bigiplogs_port}}
    type => bigiplogs
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
{{- end }}
  http {
    port  => {{.Values.input_http_port}}
    tags => ["audit"]
    user => '{{.Values.global.elk_elasticsearch_http_user}}'
    password => '{{.Values.global.elk_elasticsearch_http_password}}'
{{ if eq .Values.global.clusterType "metal" -}}
    ssl => true
    ssl_certificate => '/tls-secret/tls.crt'
    ssl_key => '/usr/share/logstash/config/tls.key'
    threads => 12
{{- end }}
  }
{{- if .Values.beats.enabled }}
  beats {
    port => {{ .Values.beats.port }}
    tags => ["audit"]
  }
{{- end }}
}

filter {
{{- if .Values.syslog.enabled }}
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
      patterns_dir => ["/audit-etc/*.grok"]
      tag_on_failure => ["_syslog_grok_failure"]
    }

    syslog_pri { }

  if [hostname] =~ "^node\d{3}r" {
    # grok {
    #   match => {
    #     "message" => [
    #                     "Alert Text: (?<alert_text>.*\n)",
    #                     "Type of Alert: (?<alert_type>.*\n)"
    #     ]
    #   }
    # }
    mutate {
      replace => { "type" => "audit" }
      add_field => { "[sap][cc][audit][source]" => "remoteboard"}
    }
    clone {
      clones => ['audit', 'syslog']
    }
  }

# Change type of audit relevant UCSM syslogs to "audit"
  if [syslogcisco_facility] {
    if [syslogcisco_facility] == "%UCSM"  and [syslogcisco_code] == "AUDIT" or [syslogcisco_facility] == "%USER" and [syslogcisco_code] == "SYSTEM_MSG" {
      mutate {
        replace => { "type" => "audit" }
        add_field => { "[sap][cc][audit][source]" => "ucsm" }
      }
      clone {
       clones => ['audit', 'syslog']
      }
    }
  }

# Change type of audit relevant HSM syslogs
  if [syslog_hostname] and [syslog_hostname] == "hsm01" {
    mutate {
        replace => { "type" => "audit" }
        add_field => { "[sap][cc][audit][source]" => "hsm" }
    }
    clone {
      clones => ['audit', 'syslog']
    }
  }

  if [type] == "syslog" and [sap][cc][audit][source] {
    mutate{
      remove_field => "[sap][cc][audit][source]"
    }
  }

 }
 {{- end }}
 {{- if eq .Values.global.clusterType "metal" }}
    if  [type] == "bigiplogs" {
           grok {
         tag_on_failure => ["bigiplogs_grok_parse-failure", "grok"]
         tag_on_timeout => ["_groktimeout"]
         patterns_dir => ["/audit-etc/*.grok"]
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
{{- end }}
    if [type] == "audit" or "audit" in [tags] {

      mutate{
        {{ if .Values.global.cluster -}}
          add_field => { "[sap][cc][cluster]" => "{{ .Values.global.cluster }}"}
        {{ end -}}
        {{ if .Values.global.region -}}
          add_field => { "[sap][cc][region]" => "{{ .Values.global.region }}"}
        {{ end -}}
      }

      if "awx" in [cluster_host_id] {
        mutate {
          add_field => { "[sap][cc][audit][source]"  => "awx" }
        }
      }

      if [event][details][serviceProvider] {
        mutate {
            add_field => { "[sap][cc][audit][source]" => "%{[event][details][serviceProvider]}" }
        }
      }

      if [sap][cc][audit][source] == "keystone-api" or  [sap][cc][audit][source] == "keystone-global-api" {
        if [user] and ![user][name] {
            mutate {
              rename => { "[user]" => "[user][name]" }
          }
        }
      }
    }
  }


output {
  if [type] == "audit" or "audit" in [tags] {
    http {
      cacert => "/usr/share/logstash/config/ca.pem"
      url => "https://{{ .Values.global.forwarding.audit.host }}"
      format => "json"
      http_method => "post"
    }
  }
{{- if .Values.syslog.enabled }}
  elseif [type] == "syslog" {
    elasticsearch {
      index => "syslog-%{+YYYY.MM.dd}"
      template => "/audit-etc/syslog.json"
      template_name => "syslog"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
{{- end }}
{{- if eq .Values.global.clusterType "metal" }}
  elseif [type] == "bigiplogs" {
    elasticsearch {
      index => "bigiplogs-%{+YYYY.MM.dd}"
      template => "/audit-etc/bigiplogs.json"
      template_name => "bigiplogs"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif [type] == "alert" and [alerts][labels][severity] == "critical"{
    elasticsearch {
      index => "alerts-critical-%{+YYYY}"
      template => "/audit-etc/alerts.json"
      template_name => "alerts"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif [type] == "alert" and [alerts][labels][severity] == "warning"{
      elasticsearch {
        index => "alerts-warning-%{+YYYY}"
        template => "/audit-etc/alerts.json"
        template_name => "alerts"
        template_overwrite => true
        hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
        user => "{{.Values.global.elk_elasticsearch_data_user}}"
        password => "{{.Values.global.elk_elasticsearch_data_password}}"
        ssl => true
    }
  }
  elseif [type] == "alert"{
    elasticsearch {
      index => "alerts-other-%{+YYYY}"
      template => "/audit-etc/alerts.json"
      template_name => "alerts"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif [type] == "deployment" {
    elasticsearch {
      index => "deployments-%{+YYYY}"
      template => "/audit-etc/deployments.json"
      template_name => "deployments"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
  elseif  [type] == "netflow" {
    elasticsearch {
      index => "netflow-%{+YYYY.MM.dd}"
      template => "/audit-etc/netflow.json"
      template_name => "netflow"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_data_user}}"
      password => "{{.Values.global.elk_elasticsearch_data_password}}"
      ssl => true
    }
  }
{{- end }}
}
