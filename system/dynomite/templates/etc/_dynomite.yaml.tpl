{{- $context := index . 0 -}}
{{- $member := index . 1 -}}
{{- $index := index . 2 -}}
dynomite-{{ $member | include "dynomite.dc" }}:
  datacenter: {{ $member | include "dynomite.dc" }}
  rack: {{ $member | include "dynomite.rack" }}
  data_store: 0
  listen: 0.0.0.0:8102
  dyn_listen: 0.0.0.0:8101
  {{- if $context.Values.dynomite.dns_txt }}
  dyn_seed_provider: simple_provider
  {{- else }}
  dyn_seed_provider: simple_provider
  dyn_seeds:
    {{- range $context.Values.dynomite.member }}
      {{- if not (eq $member .) }}
    - {{ . }}
      {{- end }}
    {{- end }}
    {{- range $context.Values.dynomite.foreign_member }}
    - {{ . }}
    {{- end }}
  {{- end }}
  servers:
    - 127.0.0.1:22122:1
  tokens: {{ $member | include "dynomite.token" }}
  stats_listen: 0.0.0.0:22222
  timeout: 150000
  mbuf_size: 16384
  max_msgs: 200000
  datastore_connections: 3
  local_peer_connections: 3
  remote_peer_connections: 3
  auto_eject_hosts: true
  server_retry_timeout: 30000
  server_failure_limit: 3
