output {
  if [netflow][fw_event] == '3' {
    elasticsearch {
      hosts => [ "${ELASTIFLOW_ES_HOST:127.0.0.1:9200}" ]
      ssl => "${ELASTIFLOW_ES_SSL_ENABLE:false}"
      # If ssl_certificate_verification is true, uncomment cacert and set the path to the certificate.
      #cacert => "/PATH/TO/CERT"
      user => "${ELASTIFLOW_ES_USER:elastic}"
      password => "${ELASTIFLOW_ES_PASSWD:changeme}"
      index => "elastiflow-4.0.1-fw-%{+YYYY.MM.dd}"
      template => "${ELASTIFLOW_TEMPLATE_PATH:/etc/logstash/elastiflow/templates}/elastiflow.template.json"
      template_name => "elastiflow-4.0.1"
      template_overwrite => "true"
    }
  }
  else {
  elasticsearch {
    hosts => [ "${ELASTIFLOW_ES_HOST:127.0.0.1:9200}" ]
    ssl => "${ELASTIFLOW_ES_SSL_ENABLE:false}"
    # If ssl_certificate_verification is true, uncomment cacert and set the path to the certificate.
    #cacert => "/PATH/TO/CERT"
    user => "${ELASTIFLOW_ES_USER:elastic}"
    password => "${ELASTIFLOW_ES_PASSWD:changeme}"
    index => "elastiflow-4.0.1-%{+YYYY.MM.dd}"
    template => "${ELASTIFLOW_TEMPLATE_PATH:/etc/logstash/elastiflow/templates}/elastiflow.template.json"
    template_name => "elastiflow-4.0.1"
    template_overwrite => "true"
    }
  }
}
