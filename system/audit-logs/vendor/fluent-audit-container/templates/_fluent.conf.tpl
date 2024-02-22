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
{{- if eq .Values.global.clusterType "metal" }}
<source>
  @type tail
  @id keystone
  path /var/log/containers/keystone-api-*.log
  exclude_path /var/log/containers/fluent*
  pos_file /var/log/keystone-octobus.log.pos
  tag keystone.*
  <parse>
  @type multi_format
    <pattern>
      format regexp
      expression /^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/
      time_key time
      time_format '%Y-%m-%dT%H:%M:%S.%NZ'
      keep_time_key true
    </pattern>
    <pattern>
      format json
      time_format '%Y-%m-%dT%H:%M:%S.%N%:z'
      time_key time
      keep_time_key true
    </pattern>
  </parse>
</source>

<source>
  @type tail
  @id keystone-global
  path /var/log/containers/keystone-global-api-*.log
  exclude_path /var/log/containers/fluent*
  pos_file /var/log/keystone-global-octobus.log.pos
  tag keystone-global.*
  <parse>
  @type multi_format
    <pattern>
      format regexp
      expression /^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/
      time_key time
      time_format '%Y-%m-%dT%H:%M:%S.%NZ'
      keep_time_key true
    </pattern>
    <pattern>
      format json
      time_format '%Y-%m-%dT%H:%M:%S.%N%:z'
      time_key time
      keep_time_key true
    </pattern>
  </parse>
</source>
{{- end }}

{{- if .Values.kubeAPIServer }}
{{- range $.Values.kubeAPIServer }}
<source>
  @type tail
  @id {{.}}kube-api
  path /var/log/containers/{{ . }}{{ $.Values.global.region }}-*-apiserver-*_kubernikus_fluentd-*.log
  exclude_path /var/log/containers/fluent*
  pos_file /var/log/{{ . }}kube-api-octobus.log.pos
  tag kubeapi.{{ . }}{{ $.Values.global.region }}.*
  <parse>
  @type multi_format
    <pattern>
      format regexp
      expression /^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/
      time_key time
      time_format '%Y-%m-%dT%H:%M:%S.%NZ'
      keep_time_key true
    </pattern>
    <pattern>
      format json
      time_format '%Y-%m-%dT%H:%M:%S.%N%:z'
      time_key time
      keep_time_key true
    </pattern>
  </parse>
</source>
<filter kubeapi.{{ . }}{{ $.Values.global.region }}.**>
  @type record_transformer
  <record>
    sap.cc.audit.source "kube-api"
    sap.cc.cluster "{{ . }}{{ $.Values.global.region }}"
    sap.cc.region "{{ $.Values.global.region }}"
  </record>
</filter>

{{- end }}
<filter kubeapi.**>
  @type parser
  @id json_parser
  key_name log
  reserve_data true
  remove_key_name_field true
  <parse>
    @type json
    time_format %Y-%m-%dT%T.%L%Z
    keep_time_key true
  </parse>
</filter>
# remove fields which cause parsing errors in elastic and are not audit relevant
<filter kubeapi.**>
  @type record_transformer
  enable_ruby
  remove_keys temp,$.requestObject.metadata.labels.app,$.requestObject.metadata.managedFields
  <record>
     temp ${ unless record.dig("requestObject","metadata","labels","app").nil?; t = record.dig("requestObject","metadata","labels","app"); record["requestObject"]["metadata"]["labels"]["app_"] = t; end; nil;}
  </record>
</filter>
{{- end }}

{{- $container_logs := .Values.default_container_logs }}
{{-  if .Values.additional_container_logs }}
{{- $container_logs = concat $container_logs .Values.additional_container_logs }}
{{- end }}
{{- range $container_logs }}
<source>
  @type tail
  @id {{ .id }}
  path {{ .path }}
  exclude_path /var/log/containers/fluent*
  pos_file /var/log/additional-containers-{{ .id }}-octobus.log.pos
  tag {{ .tag }}
  <parse>
  @type multi_format
    <pattern>
      format regexp
      expression /^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/
      time_key time
      time_format '%Y-%m-%dT%H:%M:%S.%NZ'
      keep_time_key true
    </pattern>
    <pattern>
      format json
      time_format '%Y-%m-%dT%H:%M:%S.%N%:z'
      time_key time
      keep_time_key true
    </pattern>
  </parse>
</source>
{{- if .preParseFilter }}
<filter {{ .tag }}*>
  @type grep
  @id {{ .id }}_pre_parser_filter
  {{- if eq .preParseFilter.keep true }}
  <regexp>
    key {{ .preParseFilter.key }}
    pattern {{ .preParseFilter.pattern }}
  </regexp>
  {{- else }}
  <exclude>
    key {{ .preParseFilter.key }}
    pattern {{ .preParseFilter.pattern }}
  </exclude>
  {{- end }}
</filter>
{{- end}}
{{- if .parse }}
<filter {{ .tag }}*>
  @type parser
  @id {{ .id }}_json_parser
  key_name log
  <parse>
    @type json
    time_format {{ .timeFormat | default "%Y-%m-%dT%T.%L%Z" | squote }}
    keep_time_key true
  </parse>
</filter>
{{- end }}
<filter {{ .tag }}* >
  @type kubernetes_metadata
  @id {{ .id }}_kubernetes
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  skip_labels true
  skip_container_metadata true
  skip_master_url true
  skip_namespace_metadata true
</filter>
<filter {{ .tag }}*>
  @type record_transformer
  <record>
{{- if .field }}
    {{ .field.name }} {{ .field.value | quote }}
{{- end }}
    sap.cc.cluster "{{ $.Values.global.cluster }}"
    sap.cc.region "{{ $.Values.global.region }}"
  </record>
</filter>
{{- if .filter }}
<filter {{ .tag }}*>
  @type grep
  {{- if eq .filter.keep true }}
  <regexp>
    key {{ .filter.key }}
    pattern {{ .filter.pattern }}
  </regexp>
  {{- else }}
  <exclude>
    key {{ .filter.key }}
    pattern {{ .filter.pattern }}
  </exclude>
  {{- end }}
</filter>
{{- end }}
{{- end }}

<filter falco.**>
  @type record_modifier
  <record>
    event_source ${record['source']}
  </record>
  remove_keys source
</filter>

<filter vault.**>
  @type record_transformer
  <record>
    client.user.roles ${record.dig("auth", "identity_policies") ? record.dig("auth", "identity_policies") : record.dig("auth", "token_policies")}
    client.user.name ${record.dig("auth", "metadata", "email") ? record.dig("auth", "metadata", "email") : record.dig("auth", "metadata", "role_name")}
    client.user.id ${record.dig("auth", "display_name").gsub("oidc-", "")}
    client.user.full_name ${record.dig('auth', 'metadata', 'first_name') && record.dig('auth', 'metadata', 'last_name') ? "#{record.dig('auth', 'metadata', 'first_name')} #{record.dig('auth', 'metadata', 'last_name')}" : record.dig("auth", "metadata", "role_name")}
    client.ip ${record.dig("request", "remote_address")}
    client.address ${record.dig("request", "remote_address")}
    destination.address ${record.dig("request", "path")}
  </record>
</filter>

<match fluent.**>
  @type null
</match>

# prometheus monitoring config

@include /fluentd/etc/prometheus.conf

{{- if eq .Values.global.clusterType "metal" }}
<filter keystone.** keystone-global.**>
  @type kubernetes_metadata
  @id kubernetes
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
</filter>

<filter keystone.** keystone-global.**>
  @type parser
  @id grok_parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{DATE_EU:timestamp} %{TIME:timestamp} %{NUMBER} %{NOTSPACE:loglevel} %{JAVACLASS:component} \[%{NOTSPACE:requestid} %{DATA:global_request_id} usr %{DATA:usr} prj %{DATA:prj} dom %{DATA:dom} usr-dom %{DATA:usr_domain} prj-dom %{DATA}\] %{DATA:action} %{METHOD:method} %{URIPATH:pri_path}, %{LOWER:action} (?:b')?%{NOTSPACE:user}(?:') (?:b')(?:(%{WORD:domain}|))(?:')%{GREEDYDATA:action}
    custom_pattern_path /fluentd/etc/pattern
    grok_failure_key grok_failure
  </parse>
</filter>

<filter keystone.**>
  @type record_transformer
  <record>
    sap.cc.audit.source "keystone-api"
    sap.cc.cluster "{{ .Values.global.cluster }}"
    sap.cc.region "{{ .Values.global.region }}"
  </record>
</filter>

<filter keystone-global.**>
  @type record_transformer
  <record>
    sap.cc.audit.source "keystone-gobal-api"
    sap.cc.cluster "{{ .Values.global.cluster }}"
    sap.cc.region "{{ .Values.global.region }}"
  </record>
</filter>

{{- end }}

<filter kubernetes.**>
  @type record_modifier
  @id remove
    remove_keys message,stream
</filter>

{{- if eq .Values.global.clusterType "metal"}}
<match keystone.** keystone-global.**>
  @type copy
  @id duplicate_keystone
  <store>
    @type http
    @id ocb_keystone
    endpoint "https://{{.Values.forwarding.keystone.host}}"
    tls_ca_cert_path "/etc/ssl/certs/ca-certificates.crt"
    slow_flush_log_threshold 105.0
    retryable_response_codes [429,503]
    <buffer>
      chunk_limit_size 8MB
      flush_at_shutdown true
      overflow_action block
      retry_forever true
      retry_type exponential_backoff
      retry_max_interval 60s
      flush_interval 15s
      flush_thread_count 2
    </buffer>
    <format>
      @type json
    </format>
    json_array true
  </store>
  <store>
    @type prometheus
    @id to_prometheus_keystone
    <metric>
      name fluentd_output_status_num_records_total
      type counter
      desc The total number of outgoing records
      <labels>
        node "#{ENV['K8S_NODE_NAME']}"
        container $.kubernetes.container_name
        source keystone
      </labels>
    </metric>
  </store>
</match>
{{- end }}

<match iasapi.** iaschangelog.** vault.** github-guard.** github-guard-tools.** github-guard-corp.** concourse.** falco.**>
  @type copy
  @id duplicate_tools
  <store>
    @type http
    @id ocb_audit_tools
    endpoint "https://{{.Values.global.forwarding.audit_tools.host}}"
    tls_ca_cert_path "/etc/ssl/certs/ca-certificates.crt"
    slow_flush_log_threshold 105.0
    retryable_response_codes [429,503]
    <buffer>
      chunk_limit_size 8MB
      flush_at_shutdown true
      overflow_action block
      retry_forever true
      retry_type exponential_backoff
      retry_max_interval 60s
      flush_interval 15s
      flush_thread_count 2
    </buffer>
    <format>
      @type json
    </format>
    json_array true
  </store>
  <store>
    @type prometheus
    @id to_prometheus_tools
    <metric>
      name fluentd_output_status_num_records_total
      type counter
      desc The total number of outgoing records
      <labels>
        node "#{ENV['K8S_NODE_NAME']}"
        container $.kubernetes.container_name
        source all
      </labels>
    </metric>
  </store>
</match>

<match **>
  @type copy
  @id duplicate
  <store>
    @type http
    @id ocb_audit
    endpoint "https://{{.Values.global.forwarding.audit.host}}"
    tls_ca_cert_path "/etc/ssl/certs/ca-certificates.crt"
    slow_flush_log_threshold 105.0
    retryable_response_codes [429,503]
    <buffer>
      chunk_limit_size 8MB
      flush_at_shutdown true
      overflow_action block
      retry_forever true
      retry_type exponential_backoff
      retry_max_interval 60s
      flush_interval 15s
      flush_thread_count 2
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
        source all
      </labels>
    </metric>
  </store>
</match>
