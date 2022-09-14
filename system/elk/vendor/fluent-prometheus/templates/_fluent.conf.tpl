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
  exclude_path ["/var/log/containers/fluent-prometheus*","/var/log/containers/fluent-audit-container*","/var/log/containers/fluent-audit-systemd*"]
  pos_file /var/log/fluent-prometheus.pos
  time_format %Y-%m-%dT%H:%M:%S.%N
  tag kubernetes.*
  format json
  keep_time_key true
</source>

<source>
  @type tail
  path /var/log/containers/es*
  exclude_path /var/log/containers/fluent-prometheus*
  pos_file /var/log/fluent-es.pos
  time_format %Y-%m-%dT%H:%M:%S.%N
  tag kubernetes.*
  format json
  keep_time_key true
</source>

<source>
  @type tail
  path /var/log/containers/fluent-audit*
  pos_file /var/log/fluent-prometheus-audit.pos
  time_format %Y-%m-%dT%H:%M:%S.%N
  tag audit.*
  format json
  keep_time_key true
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
  kubernetes_url https://KUBERNETES_SERVICE_HOST
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
</filter>

<filter audit.**>
  @type kubernetes_metadata
  kubernetes_url https://KUBERNETES_SERVICE_HOST
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
    pattern /because ReadonlyREST/
    tag "READONLYREST.${tag}"
  </rule>
  <rule>
    key log
    pattern /failed to parse field/
    tag "FLUENTPARSER.${tag}"
  </rule>
</match>
  <rule>
    key log
    pattern /400 - Rejected by Elasticsearch/
    tag "FLUENTREJECTED.${tag}"
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
        fluent_namespace $.kubernetes.namespace
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
      desc The total number of sucessfull retries in resolving to ES
      <labels>
        nodename "#{ENV['K8S_NODE_NAME']}"
        fluent_container $.kubernetes.pod_name
        daemontype $.kubernetes.container_name
        fluent_namespace $.kubernetes.namespace
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
        fluent_namespace $.kubernetes.namespace
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
        fluent_namespace $.kubernetes.namespace
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
        fluent_namespace $.kubernetes.namespace
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
        fluent_namespace $.kubernetes.namespace
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
        fluent_namespace $.kubernetes.namespace
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
        fluent_namespace $.kubernetes.namespace
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
        fluent_namespace $.kubernetes.namespace
      </labels>
    </metric>
  </store>
  <store>
    @type null
  </store>
</match>
