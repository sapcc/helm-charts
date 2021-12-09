input {
  http_poller {
    urls => {
      getToken => {
        url => "{{.Values.http_poller.url.token}}"
        method => POST
        user => "{{.Values.http_poller.user}}"
        password => "{{.Values.http_poller.password}}"
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
    url => "{{.Values.http_poller.url.api}}"
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
