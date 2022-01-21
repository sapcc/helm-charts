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
  schedule => { cron => "0 */1 * * *"}
  codec => "json"
  }
}
filter {

 ruby {
    init => "require 'time'"
    code => '
             upper = Time.now
             upper = upper - upper.sec - 60 * upper.min
             lower = upper - 3600
             lower = lower.strftime "%Y-%m-%dT%H.%M.%S"
             upper = upper.strftime "%Y-%m-%dT%H.%M.%S"
             event.set("[timerange][lower]", lower)
             event.set("[timerange][upper]", upper)
            '
  }

  http {
    body_format => "json"
    follow_redirects => true
    url => "{{.Values.http_poller.url.api}}?$filter=Time%20gt%20'%{[timerange][lower]}'%20and%20Time%20le%20'%{[timerange][upper]}'"
    verb => "GET"
    headers => { "Authorization" => "Bearer %{[token_response][access_token]}" }
    request_timeout => 60
    socket_timeout => 30
  }

  split{
    field => "[body][value]"
    target => "event"
  }

  kv {
     source => "[event][Message]"
     target => "[event][details]"
     field_split_pattern => "," 
     }

  ruby {
    code => '
      event.get("[event][details]").to_hash.keys.each { |k|
      if k.start_with?("202")
        event.remove("[event][details]" + "[" + k + "]")
      end
      }
    '
  }

  date{
    match => [ "[event][Time]" , "ISO8601" , "yyyy-MM-dd'T'HH.mm.ss.SSSZ" ]
    locale => "en"
    timezone => "UTC"
}

  mutate {
    remove_field => [ "token_response", "timerange", "headers", "body" ]
    add_tag => [ "{{.Values.http_poller.url.api}}"]
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
