input {
  udp {
    port => 5514
    type => esxi
  }
}
filter {
  if [type] == "esxi" and "FIREWALL_PKTLOG" in [message] {
    grok {
      match => { "message" => "<%{POSINT:syslog_pri}>%{TIMESTAMP_ISO8601:timestamp}.%{IPORHOST}.FIREWALL_PKTLOG:.%{WORD:target_suffix}.%{WORD:af_value}.%{WORD:reason}.%{WORD:action}.+.%{WORD:direction}.%{INT:length}.%{WORD:protocol}.%{IP:src_ip}/%{INT:src_port}.*%{IP:dst_ip}/%{INT:dst_port}.([SEW]+ )?%{NOTSPACE:rule_id}"}
    }
    ruby {
      init => 'require "redis"; $rc = Redis.new(url: "redis://neutron-logger-redis:6379/0")'
      code => '
      attachment = $rc.hgetall(event.get("target_suffix"))
      security_group = $rc.get(event.get("rule_id"))
      unless security_group.nil? || attachment.empty? || attachment["port"].nil? || attachment["project"].nil?
        event.set("target", attachment["port"])
        event.set("project", attachment["project"])
        event.set("security_group", security_group)
        event.remove("target_suffix")
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
  stdout { codec => rubydebug }
}
