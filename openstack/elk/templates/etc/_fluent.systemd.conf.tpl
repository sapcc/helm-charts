# Pick up all the auto-generated input config files, one for each file
# specified in the FILES_TO_COLLECT environment variable.
@include files/*

<system>
  log_level info
</system>

# All the auto-generated files should use the tag "file.<filename>".
<source>
  @type systemd
  path /var/log/journal
  <storage>
    @type local
    persistent true
    path /var/log/journal.pos
  </storage>
  tag kube-proxy
  read_from_head true
  strip_underscores true
</source>

<match **>
   @type elasticsearch
   host {{.Values.elk_elasticsearch_endpoint_host_internal}}
   port 9200
   user {{.Values.elk_elasticsearch_admin_user}}
   password {{.Values.elk_elasticsearch_admin_password}}
   index_name systemd
   type_name fluentd
   logstash_prefix systemd
   template_name "systemd"
   template_file "/fluent-etc/systemd.json"
   time_as_integer false
   @log_level info
   buffer_type "memory"
   buffer_chunk_limit 96m
   buffer_queue_limit 256
   buffer_queue_full_action exception
   slow_flush_log_threshold 40.0
   flush_interval 3s
   retry_wait 2s
   include_tag_key true
   logstash_format true
   max_retry_wait 10s
   disable_retry_limit
   request_timeout 60s
   reload_connections true
   reload_on_failure true
   resurrect_after 120
   reconnect_on_error true
   num_threads 8
</match>
