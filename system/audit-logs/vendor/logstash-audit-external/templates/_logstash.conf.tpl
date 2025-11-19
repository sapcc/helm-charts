input {
{{- if .Values.syslog.enabled }}
  udp {
    id => "input_udp"
    port  => {{.Values.input_syslog_port}}
    type => syslog
  }
  tcp {
    id => "input_tcp"
    port  => {{.Values.input_syslog_port}}
    type => syslog
  }
{{- end }}
{{- if .Values.http.enabled }}
  http {
    id => "input_http"
    port  => {{.Values.input_http_port}}
    tags => ["audit"]
    user => '${AUDIT_HTTP_USER}'
    password => '${AUDIT_HTTP_PWD}'
{{ if eq .Values.global.clusterType "metal" -}}
    ssl_enabled => true
    ssl_certificate => '/tls-secret/tls.crt'
    ssl_key => '/usr/share/logstash/config/tls.key'
    ssl_supported_protocols => ['TLSv1.2', 'TLSv1.3']
    threads => 12
{{- end }}
  }
{{- end }}
{{- if .Values.mtls.enabled }}
  http {
    id => "input_mtls"
    port  => {{.Values.input_mtls_port}}
    tags => ["kube-api"]
    ssl_enabled => true
    ssl_certificate => '/tls-secret/tls.crt'
    ssl_key => '/usr/share/logstash/config/tls.key'
    ssl_supported_protocols => ['TLSv1.2', 'TLSv1.3']
    threads => 12
  }
{{- end }}
{{- if .Values.beats.enabled }}
  beats {
    id => "input_beats"
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
                      "<%{NONNEGINT:syslog_pri}>(?:%{SYSLOGTIMESTAMP:syslog_timestamp}|%{TIMESTAMP_ISO8601:syslog_timestamp}) %{SYSLOGHOST:syslog_hostname} Severity: (?<syslog_severity>\w+), Category: (?<syslog_category>\w+), MessageID: (?<syslog_messageid>\w+), Message: %{GREEDYDATA:syslog_message}",
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

  if [hostname] =~ "^node\d{2,3}r" {
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
  }

# Set source for ucs central instances
  if [host] == "10.46.22.24" or [host] == "10.67.75.240" {
    mutate {
      replace => { "type" => "audit" }
      add_field => { "[sap][cc][audit][source]" => "ucsc" }
    }
  }

# Change type of audit relevant UCSM syslogs to "audit"
  if [syslogcisco_facility] {
    if [syslogcisco_facility] == "%UCSM"  and [syslogcisco_code] == "AUDIT" or [syslogcisco_facility] == "%USER" and [syslogcisco_code] == "SYSTEM_MSG" {
      mutate {
        replace => { "type" => "audit" }
        add_field => { "[sap][cc][audit][source]" => "ucsm" }
      }
    }
  }

# Change type of audit relevant HSM syslogs
  if [syslog_hostname] and [syslog_hostname] == "hsm01" {
    mutate {
        replace => { "type" => "audit" }
        add_field => { "[sap][cc][audit][source]" => "hsm" }
    }
  }
  if [type] == "syslog" {
    drop{}
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

      if "awx" in [logger_name] {
        mutate {
          add_field => { "[sap][cc][audit][source]"  => "awx" }
          remove_field => [ "[event_data][artifact_data]", "[event_data][changed]", "[event_data][dark]",
                            "[event_data][failures]", "[event_data][ignored]", "[event_data][ok]",
                            "[event_data][processed]", "[event_data][res]", "[event_data][rescued]",
                            "[event_data][skipped]" ]
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
    if [type] == "kube-api" or "kube-api" in [tags] {
      if [annotations]["shoot.gardener.cloud/name"] exists {
        filter {
          grok {
            match => { [annotations]["shoot.gardener.cloud/name"] => "(?<sap.cc.region>[^-]+-[^-]+-[^-]+)$" }
          }
        }
      }
      mutate{
          add_field => { "[sap][cc][cluster]" => [annotations]["shoot.gardener.cloud/name"}
          add_field => { "[sap][cc][audit][source]" => "kube-api"}
          add_field => { "[sap][cc][audit][gardener_seed]" => [annotations]["seed.gardener.cloud/name"]}
      }
    }
  }


output {
  if [sap][cc][audit][source] == "awx" {
    http {
      id => "output_awx"
      ssl_certificate_authorities => ["/usr/share/logstash/config/ca.pem"]
      url => "https://{{ .Values.global.forwarding.audit_awx.host }}"
      format => "json"
      http_method => "post"
    }
  } else if [sap][cc][audit][source] == "flatcar" {
    http {
      id => "output_flatcar"
      ssl_certificate_authorities => ["/usr/share/logstash/config/ca.pem"]
      url => "https://{{ .Values.global.forwarding.audit_auditbeat.host }}"
      format => "json"
      http_method => "post"
    }
  } else if [type] == "audit" or "audit" in [tags] {
    http {
      id => "output_else_audit"
      ssl_certificate_authorities => ["/usr/share/logstash/config/ca.pem"]
      url => "https://{{ .Values.global.forwarding.audit.host }}"
      format => "json"
      http_method => "post"
    }
  } else if [type] == "kube-api" or "kube-api" in [tags] {
    http {
      id => "output_kube-api"
      ssl_certificate_authorities => ["/usr/share/logstash/config/ca.pem"]
      url => "https://{{ .Values.global.forwarding.audit.host }}"
      format => "json"
      http_method => "post"
    }
  }
}
