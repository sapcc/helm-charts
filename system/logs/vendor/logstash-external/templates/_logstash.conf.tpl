input {
  beats {
    id => "input-beats"
    port => {{.Values.input.beats_port}}
    type => "jumpserver"
  }
}

filter {
  if  [type] == "jumpserver" {
    mutate {
        id => "jump-split"
        split => { "[host][hostname]" => "-" }
        add_field => { "fqdn" => "%{[host][hostname][0]}.cc.%{[host][hostname][1]}-%{[host][hostname][2]}-%{[host][hostname][3]}.cloud.sap" }
        remove_field => "[host][hostname]"
    }
  }
}


output {
  elseif  [type] == "jumpserver" {
    opensearch {
      id => "opensearch-jump"
      index => "jump-%{+YYYY.MM.dd}"
      hosts => ["https://{{.Values.global.opensearch.host}}:{{.Values.global.opensearch.port}}"]
      auth_type => {
        type => 'basic'
        user => "${OPENSEARCH_JUMP_USER}"
        password => "${OPENSEARCH_JUMP_PASSWORD}"
      }
      ssl => true
      ssl_certificate_verification => true
    }
  }
}
