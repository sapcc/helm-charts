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
  @id tail
  path /var/log/containers/keystone-api-*.log,/var/log/containers/keystone-global-api-*.log
  exclude_path /var/log/containers/fluentd*
  pos_file /var/log/es-containers-octobus.log.pos
  tag kubernetes.*
  <parse>
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%N
    keep_time_key true
  </parse>
</source>

<source>
  @type tail
  @id kube-api
  path /var/log/containers/{{ .Values.global.region }}-*-apiserver-*_kubernikus_fluentd-*.log,/var/log/containers/*-{{ .Values.global.region }}-*-apiserver-*_kubernikus_fluentd-*.log
  exclude_path /var/log/containers/fluentd*
  pos_file /var/log/kube-api-octobus.log.pos
  tag kubeapi.*
  <parse>
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%N
    keep_time_key true
  </parse>
</source>

{{- if .Values.additional_container_logs }}
{{- range .Values.additional_container_logs }}
<source>
  @type tail
  @id {{ .id }}
  path {{ .path }}
  exclude_path /var/log/containers/fluentd*
  pos_file /var/log/additional-containers-{{ .id }}-octobus.log.pos
  tag {{ .tag }}
  <parse>
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%N
    keep_time_key true
  </parse>
</source>
{{- if .field }}
<filter {{ .tag }}*>
  @type record_transformer
  <record>
    {{ .field.name }} {{ .field.value | quote }}
  </record>
</filter>
{{- end }}
{{- end }}
{{- end }}

<match fluent.**>
  @type null
</match>

# prometheus monitoring config

@include /fluent-bin/prometheus.conf

<filter **>
  @type kubernetes_metadata
  @id kubernetes
  kubernetes_url https://KUBERNETES_SERVICE_HOST
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  use_journal 'false'
  container_name_to_kubernetes_regexp '^(?<name_prefix>[^_]+)_(?<container_name>[^\._]+)(\.(?<container_hash>[^_]+))?_(?<pod_name>[^_]+)_(?<namespace>[^_]+)_[^_]+_[^_]+$'
</filter>

{{- if eq .Values.global.clusterType "metal" }}
<filter kubernetes.**>
  @type parser
  @id grok_parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{DATE_EU:timestamp} %{TIME:timestamp} %{NUMBER} %{NOTSPACE:loglevel} %{JAVACLASS:component} \[%{NOTSPACE:requestid} %{DATA:global_request_id} usr %{DATA:usr} prj %{DATA:prj} dom %{DATA:dom} usr-dom %{DATA:usr_domain} prj-dom %{DATA}\] %{DATA:action} %{METHOD:method} %{URIPATH:pri_path}, %{LOWER:action} (?:b')?%{NOTSPACE:user}(?:') (?:b')(?:(%{WORD:domain}|))(?:')%{GREEDYDATA:action}
    custom_pattern_path /fluent-bin/pattern
    grok_failure_key grok_failure
  </parse>
</filter>
{{- end }}

<filter kubeapi.**>
  @type parser
  @id json_parser
  key_name log
  <parse>
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%N
    keep_time_key true
  </parse>
</filter>


<filter **>
  @type record_modifier
  @id remove
    remove_keys message,stream
</filter>

<match **>
  @type copy
  @id duplicate
{{- if eq .Values.global.clusterType "metal"}}
  <store>
    @type http
    @id to_octobus
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
      flush_interval 1s
    </buffer>
    <format>
      @type json
    </format>
    json_array true
  </store>
{{- end }}
  <store>
    @type http
    @id to_logstash
    {{ if eq .Values.global.clusterType "metal" -}}
    endpoint "https://logstash-audit-external.{{.Values.global.region}}.{{.Values.global.tld}}"
    {{ else -}}
    endpoint "http://logstash-audit-external.audit-logs:{{.Values.global.https_port}}"
    {{ end -}}
    <auth>
      method basic
      username {{.Values.global.elk_elasticsearch_http_user}}
      password {{.Values.global.elk_elasticsearch_http_password}}
    </auth>
    slow_flush_log_threshold 105.0
    retryable_response_codes [503]
    <buffer>
      queue_limit_length 24
      chunk_limit_size 8MB
      flush_at_shutdown true
      overflow_action block
      retry_forever true
      retry_type periodic
      flush_interval 1s
    </buffer>
    <format>
      @type json
    </format>
    json_array true
  </store>
  <store>
    @type prometheus
    @id to_prometheus
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
