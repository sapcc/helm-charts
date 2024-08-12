input {
  udp {
    port => 5514
    type => esxi
  }
}
filter {
  if [type] == "esxi" and "FIREWALL_PKTLOG" in [message] {
    grok {
      match => { "message" => "<%{POSINT:syslog_pri}>%{TIMESTAMP_ISO8601:timestamp}.%{IPORHOST}.FIREWALL_PKTLOG:.%{WORD:target_suffix}.%{WORD:af_value}.%{GREEDYDATA:message}" }
      overwrite => [ "message" ]
    }
    grok {
      "match" => { "message" => [
        "match.%{WORD:action}.%{INT:rule_id}.%{WORD:direction}.%{INT:length}.(?<protocol>PROTO [0-9]+).%{IP:src_ip}->%{IP:dst_ip}.%{NOTSPACE:sg_id}",
        "match.%{WORD:action}.%{INT:rule_id}.%{WORD:direction}.%{INT:length}.%{WORD:protocol}.%{IP:src_ip}/%{INT:src_port}->%{IP:dst_ip}/%{INT:dst_port}.%{WORD:tcp_flags}.%{NOTSPACE:sg_id}",
        "match.%{WORD:action}.%{INT:rule_id}.%{WORD:direction}.%{INT:length}.%{WORD:protocol}.%{INT:icmp_type}.%{INT:icmp_code}.%{IP:src_ip}->%{IP:dst_ip}.%{NOTSPACE:sg_id}",
        "match.%{WORD:action}.%{INT:rule_id}.%{WORD:direction}.%{INT:length}.%{WORD:protocol}.%{IP:src_ip}->%{IP:dst_ip}.%{NOTSPACE:sg_id}",
        "TERM.%{INT:rule_id}.%{WORD:direction}.%{WORD:protocol}.%{IP:src_ip}/%{INT:src_port}->%{IP:dst_ip}/%{INT:dst_port}.%{INT:in_count}/%{INT:out_count}.%{INT:in_size}/%{INT:out_size}.?%{NOTSPACE:sg_id}",
        "TERM.%{INT:rule_id}.%{WORD:direction}.%{WORD:protocol}.%{INT:icmp_type}.%{INT:icmp_code}.%{IP:src_ip}->%{IP:dst_ip}.%{INT:in_count}/%{INT:out_count}.%{INT:in_size}/%{INT:out_size}.?%{NOTSPACE:sg_id}",
        "TERM.%{WORD:action}.%{INT:rule_id}.%{WORD:direction}.%{WORD:protocol}.%{IP:src_ip}/%{INT:src_port}->%{IP:dst_ip}/%{INT:dst_port}.%{INT:in_count}/%{INT:out_count}.%{INT:in_size}/%{INT:out_size}.?%{NOTSPACE:sg_id}",
        "%{WORD:action}.%{INT:rule_id}.%{WORD:direction}.%{WORD:protocol}.%{WORD:tcp_flags}.%{IP:src_ip}/%{INT:src_port}->%{IP:dst_ip}/%{INT:dst_port}.%{INT:in_count}/%{INT:out_count}.%{INT:in_size}/%{INT:out_size}.?%{NOTSPACE:sg_id}"
      ] }
    }

    if "_grokparsefailure" not in [tags] {
      ruby {
        init => 'require "sequel"; $rc = Sequel.connect("jdbc:mysql://{{include "db_host_mysql" .}}/{{.Values.db_name}}?user=${NEUTRON_DB_USER}&password=${NEUTRON_DB_PASSWORD}")'
        code => '
        event_map = {"PASS" => "ACCEPT", "DROP" => "DROP"}
        event.set("action", "TERM") if event.get("action").nil?
        res = $rc[:logs].select(:target_id, :resource_id, :project_id).where(resource_type: "security_group").where(:enabled).where(event: [event_map[event.get("action")], "ALL"]).where(Sequel.like(:resource_id, event.get("sg_id") + "%")).where(Sequel.like(:target_id,"%" + event.get("target_suffix"))).or(target_id: nil).first
        unless res.nil?
          if event.get("length").nil?
            event.set("length", event.get("in_size").to_i + event.get("out_size").to_i)
          end
          event.set("port", res[:target_id].nil? ? event.get("target_suffix") : res[:target_id])
          event.set("project", res[:project_id])
          event.set("security_group", res[:resource_id])
          event.set("src_port", "n/a") if event.get("src_port").nil?
          event.set("dst_port", "n/a") if event.get("dst_port").nil?
          event.remove("target_suffix")
          event.remove("sg_id")
          event.remove("message")
        else
          event.cancel
        end
        '
      }
    }
  } else {
    drop { }
  }
}
output {
  if "_grokparsefailure" in [tags] {
    stdout { codec => rubydebug }
  } else {
    {{- if .Values.logger.persistence.enabled }}
    file {
      path => "/data/%{project}.log"
      codec => line { format => "%{timestamp} %{af_value} %{action} %{direction} len:%{length} proto:%{protocol} src_ip:%{src_ip} src_port:%{src_port} dst_ip:%{dst_ip} dst_port:%{dst_port} flags:%{tcp_flags} port:%{port} security_group:%{security_group}" }
    }
    {{- else }}
    stdout { codec => rubydebug }
    {{- end }}
  }
}
