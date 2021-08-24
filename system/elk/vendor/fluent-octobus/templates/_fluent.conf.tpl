# This Fluentd configuration file enables the collection of log files
# that can be specified at the time of its creation in an environment
# variable, assuming that the config_generator.sh script runs to generate
# a configuration file for each log file to collect.
# Logs collected will be sent to the cluster's Elasticsearch service.
#
# Currently the collector uses a text format rather than allowing the user
# to specify how to parse each file.

# Pick up all the auto-generated input config files, one for each file
# specified in the FILES_TO_COLLECT environment variable.
@include files/*

<system>
  log_level warn
</system>

<label @FLUENT_LOG>
  <match fluent.*>
    @type stdout
  </match>
</label>

# All the auto-generated files should use the tag "file.<filename>".
<source>
  @type tail
  path /var/log/containers/keystone-api-*.log
  exclude_path /var/log/containers/fluentd*
  pos_file /var/log/es-containers-octobus.log.pos
  time_format %Y-%m-%dT%H:%M:%S.%N
  tag kubernetes.*
  format json
  keep_time_key true
</source>

<match fluent.**>
  @type null
</match>

# prometheus monitoring config

@include /fluent-bin/prometheus.conf

<filter kubernetes.**>
  @type kubernetes_metadata
  kubernetes_url https://KUBERNETES_SERVICE_HOST
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  use_journal 'false'
  container_name_to_kubernetes_regexp '^(?<name_prefix>[^_]+)_(?<container_name>[^\._]+)(\.(?<container_hash>[^_]+))?_(?<pod_name>[^_]+)_(?<namespace>[^_]+)_[^_]+_[^_]+$'
</filter>

<filter kubernetes.**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{DATE_EU:timestamp} %{TIME:timestamp} %{NUMBER} %{NOTSPACE:loglevel} %{JAVACLASS:component} \[%{NOTSPACE:requestid} usr %{DATA:usr} prj %{DATA:prj} dom %{DATA:dom} usr-dom %{DATA:usr_domain} prj-dom %{DATA}\] %{GREEDYDATA:action} %{METHOD:method} %{URIPATH:pri_path} %{LOWER:action} %{NOTSPACE:user} %{WORD:domain} %{GREEDYDATA:action}
    custom_pattern_path /fluent-bin/pattern
    grok_failure_key grok_failure
  </parse>
</filter>

<filter kubernetes.**>
  @type record_modifier
    remove_keys message,stream
</filter>

<match kubernetes.**>
  @type copy
  <store>
    @type http
    endpoint "https://{{.Values.forwarding.keystone.host}}"
    tls_ca_cert_path "/etc/ssl/certs/ca-certificates.crt"
    slow_flush_log_threshold 105.0
    retryable_response_codes [503]
    <buffer>
      queue_limit_length 24
      chunk_limit_size 8MB
      flush_at_shutdown true
      overflow_action block
      retry_forever true
      retry_type periodic
      flush_interval 8s
    </buffer>
    <format>
      @type json
    </format>
    json_array true
  </store>
  <store>
    @type prometheus
    <metric>
      name fluentd_output_status_num_records_total
      type counter
      desc The total number of outgoing records
      <labels>
        node "#{ENV['K8S_NODE_NAME']}"
        container $.kubernetes.container_name
      </labels>
    </metric>
  </store>
</match>
