input {
  http_poller {
    urls => {
      getToken => {
        url => "{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}"
        method => POST
        user => "69334663-f28f-37d3-9d65-129a7b4d55d9"
        password => "e4874bd0-acdf-3287-ae54-189bfa3517b2"
     }
  }
  target => "token_response"
  request_timeout => 60
  schedule => { every => "1m"}
  codec => "json"
  }
}
filter {
  http {
    body_format => "json"
    follow_redirects => true
    url => "https://api.eu1.hana.ondemand.com/auditlog/v1/accounts/ajfc1jphz/AuditLogRecordsIds?$filter=Time%20gt%20'2021-12-07T00.00.00'%20and%20Time%20le%20'2021-12-07T06.00.00'%20and%20Category%20eq%20'audit.authentication'&$top=10000"
    verb => "GET"
    headers => { "Authorization" => "Bearer %{[token_response][access_token]}" }
    request_timeout => 60
    socket_timeout => 30
  }
 mutate {
  remove_field => [ "token_response" ]
  }
}
output {
    elasticsearch {
      index => "audit-%{+YYYY.MM.dd}"
      template => "/logstash-etc/audit.json"
      template_name => "audit"
      template_overwrite => true
      hosts => ["{{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.elk_cluster_region}}.{{.Values.global.tld}}:{{.Values.global.elk_elasticsearch_ssl_port}}"]
      user => "{{.Values.global.elk_elasticsearch_audit_user}}"
      password => "{{.Values.global.elk_elasticsearch_audit_password}}"
      ssl => true
    }
}
