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
  automatic_retries => 3
  schedule => { cron => "*/5 * * * *"}
  codec => "json"
  }
}
filter {

 ruby {
    init => "require 'time'"
    code => '
             upper = Time.now
             lower = upper - 300
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
    socket_timeout => 20
    automatic_retries => 3
  }

  if [body][value] {

    split {
      field => "[body][value]"
      target => "event"
    }
    if [event][Message] {
      kv {
        source => "[event][Message]"
        target => "[event][details]"
        field_split_pattern => ", "
        whitespace => "strict"
        }

      if [event][details]{
        ruby {
          code => '
            event.get("[event][details]").to_hash.keys.each { |k|
            if k.start_with?("202")
              event.remove("[event][details]" + "[" + k + "]")
            end
            }
          '
        }
      }

      date{
        match => [ "[event][Time]" , "ISO8601" , "yyyy-MM-dd'T'HH.mm.ss.SSSZ" ]
        locale => "en"
        timezone => "UTC"
      }
    }

    mutate {
      remove_field => [ "token_response", "timerange", "headers", "body" ]
      add_tag => [ "{{.Values.http_poller.url.api}}"]
    }
  }
}
output {
    http{
    {{ if eq .Values.global.clusterType "metal" -}}
      url => "https://logstash-audit-external.{{.Values.global.region}}.{{.Values.global.tld}}"
    {{ else -}}
      url => "https://logstash-audit-external.audit-logs:{{.Values.global.https_port}}"
    {{ end -}}
    format => "json"
    http_method => "post"
    headers => { "Authorization" =>  "Basic {{ template "httpBasicAuth" . }}" }
    }
}
