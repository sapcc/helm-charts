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

@include /fluentd/etc/prometheus.conf

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
    key "syslog_identifier"
    pattern /(sshd|systemd-timesyncd|useradd)/
  </regexp>
</filter>

<filter **>
  @type record_transformer
  <record>
    sap.cc.audit.source "flatcar"
    sap.cc.cluster "{{ .Values.global.cluster }}"
    sap.cc.region "{{ .Values.global.region }}"
  </record>
</filter>

<match **>
  @type copy
  <store>
    @type http
    endpoint "https://{{.Values.global.forwarding.audit_auditbeat.host}}"
    tls_ca_cert_path "/etc/ssl/certs/ca-certificates.crt"
    slow_flush_log_threshold 105.0
    retryable_response_codes [503]
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
