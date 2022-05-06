input {
  udp {
    port => 5514
    type => esxi
  }
}
filter {
  if [type] == "esxi" and "FIREWALL_PKTLOG" in [message] {
    grok {
      match => { "message" => "<%{POSINT:syslog_pri}>%{TIMESTAMP_ISO8601:timestamp}.%{IPORHOST}.FIREWALL_PKTLOG:.%{WORD:target_suffix}.%{WORD:af_value}.match.%{WORD:action}.+.%{WORD:direction}.%{INT:length}.%{WORD:protocol}.%{IP:src_ip}/%{INT:src_port}.*%{IP:dst_ip}/%{INT:dst_port}.([SEW]+ )?%{NOTSPACE:sg_id}"}
      tag_on_failure => [ ]
    }
    if "_grokparsefailure" in [tags] {
      drop { }
    }
    ruby {
      init => 'require "redis"; $rc = Redis.new(url: "redis://neutron-nsxv3-redis:6379/0")'
      code => '
      attachment = $rc.hgetall(event.get("target_suffix"))
      security_group = $rc.get("SG_" + event.get("sg_id"))
      unless security_group.nil? || attachment.empty? || attachment["port"].nil? || attachment["project"].nil?
        event.set("target", attachment["port"])
        event.set("project", attachment["project"])
        event.set("security_group", security_group)
        event.remove("target_suffix")
        event.remove("sg_id")
        event.remove("message")
      else
        event.cancel
      end
      '
    }
  } else {
    drop { }
  }
}
output {
{{- if .Values.logger.persistence.enabled }}
 file {
   path => "/data/%{project}/%{+YYYY-MM-dd}.log"
   codec => line { format => "%{timestamp} %{af_value} %{action} %{direction} len:%{length} proto:%{protocol} src:%{src_ip}:%{src_port} dst:%{dst_ip}:%{dst_port} port:%{target} security_group:%{security_group}" }
 }
{{- else }}
  stdout { codec => rubydebug }
{{- end }}
}
