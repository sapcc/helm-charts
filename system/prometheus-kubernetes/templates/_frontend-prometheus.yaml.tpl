- job_name: 'prometheus-collector-federation'
  scrape_interval: 80s
  scrape_timeout: 75s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^absent_metrics_operator.+"}'
      - '{__name__=~"^active_job_.+"}'
      - '{__name__=~"^aggregated:.+"}'
      - '{__name__=~"^alertmanager_.+"}'
      - '{__name__=~"^apiserver_.+"}'
      - '{__name__="backup_last_success"}'
      - '{__name__=~"^bind_.+"}'
      - '{__name__=~"^bird_.+"}'
      - '{__name__=~"^broker_.+"}'
      - '{__name__=~"^certmanager_.+"}'
      - '{__name__=~"^concourse_.+"}'
      - '{__name__=~"^container_cpu.+"}'
      - '{__name__=~"^container_fs.+"}'
      - '{__name__=~"^container_memory_.+"}'
      - '{__name__=~"^container_network_.+"}'
      - '{__name__=~"^container_spec_.+"}'
      - '{__name__=~"^container_scrape_error"}'
      - '{__name__=~"^container_start_time_seconds"}'
      - '{__name__=~"^container_task_state"}'
      - '{__name__=~"^controller_runtime_.+"}'
      - '{__name__=~"^dnsmasq.+"}'
      - '{__name__=~"^doop_agent_.+"}'
      - '{__name__=~"^etcd_.+"}'
      - '{__name__=~"^etcdbr_.+"}'
      - '{__name__=~"^gatekeeper_.+"}'
      - '{__name__=~"^go_.+"}'
      - '{__name__=~"^http_.+"}'
      - '{__name__=~"^ingress_.+"}'
      - '{__name__=~"^ipmi_.+"}'
      - '{__name__=~"^klog_.+"}'
      - '{__name__=~"^kube_.+"}'
      - '{__name__=~"^kubelet_.+"}'
      - '{__name__=~"^machine_cpu_cores"}'
      - '{__name__=~"^machine_memory_bytes"}'
      - '{__name__=~"^maintenance_controller_.+"}'
      - '{__name__=~"^metrics_.+"}'
      - '{__name__=~"^nginx_.+"}'
      - '{__name__=~"^node_.+"}'
      - '{__name__=~"^ntp_drift_seconds$"}'
      - '{__name__=~"^pg_.+"}'
      - '{__name__=~"^probe_success$"}'
      - '{__name__=~"^probe_dns_lookup_time_seconds$"}'
      - '{__name__=~"^probe_duration_seconds$"}'
      - '{__name__=~"^probe_http_duration_seconds$"}'
      - '{__name__=~"^probe_http_status_code$"}'
      - 'probe_ssl_earliest_cert_expiry{region_probed_from={{ required ".Values.global.region missing" .Values.global.region|quote }}}'
      - '{__name__=~"^process_.+"}'
      - '{__name__=~"^prometheus_.+"}'
      - '{__name__=~"^puma_.+"}'
      - '{__name__=~"^quay_.+"}'
      - '{__name__=~"^rabbitmq_.+"}'
      - '{__name__=~"^rest_client_.+"}'
      - '{__name__=~"^scheduler_.+"}'
      - '{__name__=~"^scrape_duration_seconds"}'
      - '{__name__=~"^secrets_exporter_certificate_not_after"}'
      - '{__name__=~"^coredns.+"}'
      - '{__name__=~"^tcp_probe.+"}'
      - '{__name__=~"^unbound_.+"}'
      - '{__name__=~"^up"}'
      - '{__name__=~"^uwsgi_.+"}'
      - '{__name__=~"^vice_president_.+"}'
      - '{__name__=~"^webhook_.+"}'
      - '{__name__=~"^watchcache_.+"}'
      - '{__name__=~"^admission|daemonset|deployment|disruption|endpoint|job|namespace|petset|replicaset|serviceaccount.+"}'
      - '{__name__=~"^ns_exporter.+"}'
      - '{__name__=~"^total"}'
      - '{__name__=~"^success"}'
      - '{__name__=~"^latency"}'
      - '{__name__=~"^pvc_usage"}'
      - '{__name__=~"^envoy_.+"}'
      - '{__name__=~"^auditbeat_.+"}'
      - '{__name__=~"^vault.+"}'

  # Add region label to all metrics, don't delete this without knowing what you are doing.
  relabel_configs:
     - action: replace
       target_label: region
       replacement: {{ required ".Values.global.region undefined" .Values.global.region }}

  metric_relabel_configs:
    - action: replace
      source_labels: [__name__]
      target_label: __name__
      regex: aggregated:(.+)
      replacement: $1

  static_configs:
    - targets:
      - 'prometheus-collector-kubernetes.{{ .Release.Namespace }}.svc:9090'
