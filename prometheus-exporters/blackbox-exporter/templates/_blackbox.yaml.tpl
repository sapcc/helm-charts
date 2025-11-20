modules:
  http_2xx:
    prober: http
    http:
      fail_if_not_ssl: false
      preferred_ip_protocol: "ip4"
      follow_redirects: true
      tls_config:
        insecure_skip_verify: true
  https_2xx:
    prober: http
    http:
      fail_if_not_ssl: true
      preferred_ip_protocol: "ip4"
      follow_redirects: true
  http_401:
    prober: http
    http:
      fail_if_not_ssl: true
      preferred_ip_protocol: "ip4"
      valid_status_codes: [401]
  http_post_4xx:
    prober: http
    http:
      fail_if_not_ssl: true
      preferred_ip_protocol: "ip4"
      method: POST
  http_403:
    prober: http
    http:
      follow_redirects: true
      valid_status_codes: [403]
      tls_config:
        insecure_skip_verify: true
  https_403:
    prober: http
    http:
      follow_redirects: true
      fail_if_not_ssl: true
      valid_status_codes: [403]
  # used for probing kubernikus kluster api
  http_200_403:
    prober: http
    http:
      follow_redirects: true
      valid_status_codes: [200,403]
      tls_config:
        insecure_skip_verify: true
  icmp:
    prober: icmp
    icmp:
      preferred_ip_protocol: "ip4"
  tcp_connect:
    prober: tcp
    timeout: 10s
    tcp:
      preferred_ip_protocol: "ip4"
  sentry:
    prober: http
    http:
      fail_if_not_ssl: true
      preferred_ip_protocol: "ip4"
      follow_redirects: true
      fail_if_body_not_matches_regexp:
        - '"WarningStatusCheck":true'
        - '"CeleryAppVersionCheck":true'
        - '"CeleryAliveCheck":true'
        - '"problems":\[\]'
  docs_home_content:
    prober: http
    timeout: 10s
    http:
      valid_status_codes: [200]
      method: GET
      fail_if_body_not_matches_regexp:
        - "SAP Converged Cloud"
  docs_training_content:
    prober: http
    timeout: 10s
    http:
      valid_status_codes: [200]
      method: GET
      fail_if_body_not_matches_regexp:
        - "Welcome to the SAP Converged Cloud classroom Training"

  opensearch-dashboard:
    prober: http
    timeout: 10s
    http:
      valid_status_codes: [401]
      method: GET
      fail_if_body_not_matches_regexp:
        - "Unauthorized"

  opensearch-client:
    prober: http
    timeout: 10s
    http:
      valid_status_codes: [200]
      method: GET
