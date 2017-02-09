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
  log_level info
</system>

# All the auto-generated files should use the tag "file.<filename>".
<source>
  @type tail
  path /var/log/containers/*.log
  pos_file /var/log/es-containers.log.pos
  time_format %Y-%m-%dT%H:%M:%S.%N
  tag kubernetes.*
  format json
  read_from_head true
  keep_time_key true
</source>

<source>
  @type tail
  format none
  path /var/log/salt/minion
  pos_file /var/log/gcp-salt.pos
  tag salt
</source>

<source>
  @type tail
  format none
  path /var/log/startupscript.log
  pos_file /var/log/es-startupscript.log.pos
  tag startupscript
</source>

<source>
  @type tail
  format none
  path /var/log/docker.log
  pos_file /var/log/es-docker.log.pos
  tag docker
</source>

<source>
  @type tail
  format none
  path /var/log/etcd.log
  pos_file /var/log/es-etcd.log.pos
  tag etcd
</source>

<source>
  @type tail
  format none
  path /var/log/kubelet.log
  pos_file /var/log/es-kubelet.log.pos
  tag kubelet
</source>

<source>
  @type tail
  format none
  path /var/log/kube-apiserver.log
  pos_file /var/log/es-kube-apiserver.log.pos
  tag kube-apiserver
</source>

<source>
  @type tail
  format none
  path /var/log/kube-controller-manager.log
  pos_file /var/log/es-kube-controller-manager.log.pos
  tag kube-controller-manager
</source>

<source>
  @type tail
  format none
  path /var/log/kube-scheduler.log
  pos_file /var/log/es-kube-scheduler.log.pos
  tag kube-scheduler
</source>

<filter kubernetes.**>
  @type kubernetes_metadata
  kubernetes_url https://KUBERNETES_SERVICE_HOST
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
</filter>

<match **>
   @type elasticsearch
   host {{.Values.monasca_elasticsearch_endpoint_host_internal}}
   port {{.Values.monasca_elasticsearch_port_internal}}
   user {{.Values.monasca_elasticsearch_data_user}}
   password {{.Values.monasca_elasticsearch_data_password}}
   time_as_integer false
   @log_level info
   buffer_type "memory"
   buffer_chunk_limit 96m
   buffer_queue_limit 256
   flush_interval 5s
   retry_wait 5s
   include_tag_key true
   logstash_format true
   max_retry_wait 30s
   disable_retry_limit
   request_timeout 5s
   reload_connections true
   reload_on_failure true
   resurrect_after 120
   reconnect_on_error true
   num_threads 8
 </match>
