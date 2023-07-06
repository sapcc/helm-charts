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
  path /var/log/containers/fluent*
  exclude_path ["/var/log/containers/fluent-prometheus*","/var/log/containers/fluent-audit*"]
  pos_file /var/log/fluent-prometheus.pos
  tag kubernetes.*
  <parse>
    @type multi_format
     <pattern>
       format regexp
       expression /^(?<time>.+)\s(?<stream>stdout|stderr)\s(?<logtag>F|P)\s(?<log>.*)$/
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
  read_from_head
  @log_level warn
</source>

<source>
  @type tail
  path /var/log/containers/es*
  exclude_path /var/log/containers/fluent-prometheus*
  pos_file /var/log/fluent-es.pos
  tag kubernetes.*
  <parse>
    @type multi_format
     <pattern>
       format regexp
       expression /^(?<time>.+)\s(?<stream>stdout|stderr)\s(?<logtag>F|P)\s(?<log>.*)$/
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
  read_from_head
  @log_level warn
</source>

<source>
  @type tail
  path /var/log/containers/fluent-audit*
  exclude_path /var/log/containers/fluent-prometheus*
  pos_file /var/log/fluent-prometheus-audit.pos
  tag audit.*
  <parse>
    @type multi_format
     <pattern>
       format regexp
       expression /^(?<time>.+)\s(?<stream>stdout|stderr)\s(?<logtag>F|P)\s(?<log>.*)$/
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
  read_from_head
  @log_level warn
</source>

<match fluent.**>
  @type null
</match>

# expose metrics in prometheus format

<source>
  @type prometheus
  bind 0.0.0.0
  port 24231
  metrics_path /metrics
</source>

<filter kubernetes.**>
  @type kubernetes_metadata
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
</filter>

<filter audit.**>
  @type kubernetes_metadata
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
</filter>

# metrics
# # count number of incoming records per tag
<filter kubernetes.**>
  @type prometheus
  <metric>
    name prom_fluentd_input_status_num_records_total
    type counter
    desc The total number of incoming records
    <labels>
      hostname ${hostname}
      nodename "#{ENV['K8S_NODE_NAME']}"
      fluent_namespace $.kubernetes.namespace_name
    </labels>
  </metric>
</filter>

<filter audit.**>
  @type prometheus
  <metric>
    name prom_fluentd_audit_input_status_num_records_total
    type counter
    desc The total number of incoming records from audit fluentds
    <labels>
      hostname ${hostname}
      nodename "#{ENV['K8S_NODE_NAME']}"
      fluent_namespace $.kubernetes.namespace_name
    </labels>
  </metric>
</filter>

<match kubernetes.**>
  @type rewrite_tag_filter
  <rule>
    key log
    pattern /ResolvError/
    tag "FLUENTERROR.${tag}"
  </rule>
  <rule>
    key log
    pattern /retry succeeded/
    tag "FLUENTSUCCEED.${tag}"
  </rule>
  <rule>
    key log
    pattern /Connection reset/
    tag "FLUENTRESET.${tag}"
  </rule>
  <rule>
    key log
    pattern /failed to parse field/
    tag "FLUENTPARSER.${tag}"
  </rule>
  <rule>
    key log
    pattern /connect_write timeout reached/
    tag "FLUENTTIMEOUT.${tag}"
  </rule>
  <rule>
    key log
    pattern /400 - Rejected by/
    tag "FLUENTREJECTED.${tag}"
  </rule>
  <rule>
    key log
    pattern /slow_flush_log_threshold/
    tag "FLUENTSLOWFLUSH.${tag}"
  </rule>
  <rule>
    key log
    pattern /rejected execution of coordinating operation/
    tag "FLUENTRATELIMIT.${tag}"
  </rule>
  <rule>
    key log
    pattern /encountered fetching pod metadata/
    tag "METADATA.${tag}"
  </rule>
  <rule>
    key log
    pattern /(unreadable. It is excluded|Skip update_watcher because watcher has been already updated by other inotify event)/
    tag "FLUENTDTAILSTALLED.${tag}"
  </rule>
</match>

<match FLUENTERROR.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_output_resolv_error
      type counter
      desc The total number of resolve errata to ES
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        daemontype $.kubernetes.container_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTSUCCEED.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_output_retry_succeed
      type counter
      desc The total number of sucessfull retries in resolving to Elastic
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        daemontype $.kubernetes.container_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTRESET.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_output_connreset_error
      type counter
      desc The total number of connection reset errors
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        daemontype $.kubernetes.container_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTPARSER.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_parser_exception
      type counter
      desc The total number of fluent parser exceptions
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        daemontype $.kubernetes.container_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTREJECTED.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_elastic_400
      type counter
      desc The total number of elastic rejected 400 error
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        daemontype $.kubernetes.container_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match READONLYREST.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_elastic_readonlyrest_error
      type counter
      desc The total number of readonlyrest plugin errata
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTTIMEOUT.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_timeout_error
      type counter
      desc The total number of fluent timeout reached errors
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTESREADONLY.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_readonlyrest_error
      type counter
      desc The total number of fluent elastic client readonlyrest errors
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTSLOWFLUSH.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_slowflush_warn
      type counter
      desc The total number of fluent slow flush warnings
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTRATELIMIT.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_elk_rate_limit
      type counter
      desc The total number of fluent elk 429 rate limit
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match METADATA.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_kubernetes_api_timeout
      type counter
      desc Metadata cannot be fetched from kubernetes api
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match audit.**>
  @type rewrite_tag_filter
  <rule>
    key log
    pattern /ResolvError/
    tag "FLUENTAUDITERROR.${tag}"
  </rule>
  <rule>
    key log
    pattern /failed to parse field/
    tag "FLUENTAUDITPARSER.${tag}"
  </rule>
  <rule>
    key log
    pattern /Connection reset/
    tag "FLUENTAUDITRESET.${tag}"
  </rule>
  <rule>
    key log
    pattern /connect_write timeout reached/
    tag "FLUENTAUDITTIMEOUT.${tag}"
  </rule>
  <rule>
    key log
    pattern /(unreadable. It is excluded|Skip update_watcher because watcher has been already updated by other inotify event)/
    tag "FLUENTDTAILSTALLED.${tag}"
  </rule>
</match>

<match FLUENTDTAILSTALLED.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_tail_stalled
      type counter
      desc Tail stalled for a log file
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTAUDITERROR.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_audit_output_resolv_error
      type counter
      desc The total number of resolve errata to ES for fluent audit
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        daemontype $.kubernetes.container_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTAUDITRESET.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_audit_output_connreset_error
      type counter
      desc The total number of connection reset errors for fluentd audit
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        daemontype $.kubernetes.container_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTAUDITPARSER.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_audit_parser_exception
      type counter
      desc The total number of fluent audit logs parser exceptions
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        daemontype $.kubernetes.container_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>

<match FLUENTAUDITTIMEOUT.**>
  @type copy
  <store>
    @type prometheus
    <metric>
      name prom_fluentd_audit_timeout_error
      type counter
      desc The total number of fluent audit timeout reached errors
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        daemontype $.kubernetes.container_name
        fluent_namespace $.kubernetes.namespace_name
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>
