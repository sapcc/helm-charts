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
  @type systemd
  path /var/log/journal
  <storage>
    @type local
    persistent true
    path /var/log/journal.audit.pos
  </storage>
  tag systemd
  read_from_head true
</source>

# prometheus monitoring config

@include /fluent-etc/prometheus.conf

<filter **>
  @type systemd_entry
#  field_map {"MESSAGE": "log", "_PID": ["process", "pid"], "_CMDLINE": "process", "_COMM": "cmd"}
#  field_map_strict false
  fields_lowercase true
  fields_strip_underscores true
</filter>

<filter **>
  @type grep
  <regexp>
    key message
    pattern /(audit|sshd)/
  </regexp>
  <regexp>
    key syslog_identifier
    pattern /sssd/
  </regexp>
</filter>

<match **>
  @type copy
  <store>
    @type http
    {{ if eq .Values.global.clusterType "scaleout" -}}
    endpoint "https://logstash-audit-external.elk:{{.Values.global.https_port}}"
    {{ else -}}
    endpoint "https://logstash-audit-external.{{.Values.global.region}}.{{.Values.global.tld}}"
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
      name fluentd_audit_systemd_output_status_num_records_total
      type counter
      desc The total number of outgoing records
      <labels>
        nodename "#{ENV['NODENAME']}"
      </labels>
    </metric>
  </store>
</match>
