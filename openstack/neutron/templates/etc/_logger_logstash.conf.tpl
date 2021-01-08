input {
  udp {
    port => 5514
    type => esxi
  }
}
filter {
  if [type] == "esxi" and "match" in [message] {
    grok {
      match => { "message" => "<%{POSINT:syslog_pri}>%{TIMESTAMP_ISO8601:timestamp}.%{IPORHOST}.FIREWALL_PKTLOG:.%{WORD:target_suffix}.%{WORD:af_value}.%{WORD:reason}.%{WORD:action}.+.%{WORD:direction}.%{INT:length}.%{WORD:protocol}.%{IP:src_ip}/%{INT:src_port}.*%{IP:dst_ip}/%{INT:dst_port}.%{NOTSPACE:rule_id}"}
    }
    ruby {
      init => 'require "redis"; $rc = Redis.new(path: "/var/run/redis/redis.sock", db: 0)'
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
  s3 {
    endpoint => "{{.Values.logger.logstash.endpoint}}"
    access_key_id => "{{.Values.logger.logstash.access_key_id}}"
    secret_access_key => "{{.Values.logger.logstash.secret_access_key}}"
    region => "{{.Values.logger.logstash.region}}"
    bucket => "{{.Values.logger.logstash.bucket}}"
    prefix => "%{project}"
    codec => "json_lines"
    canned_acl => "bucket-owner-full-control"
    retry_count => 0
    upload_workers_count => 8
    validate_credentials_on_root_bucket => false
    additional_settings => {
      "follow_redirects" => false
      "force_path_style" => true
    }
  }
}