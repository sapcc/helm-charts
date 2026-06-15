{{/*
SPDX-FileCopyrightText: 2024 SAP SE or an SAP affiliate company and Greenhouse contributors
SPDX-License-Identifier: Apache-2.0
*/}}
{{- define "containerd.receiver" }}
file_log/containerd:
  include_file_path: true
  include: [ /var/log/pods/*/*/*.log ]
  exclude:
{{- if .Values.openTelemetry.logsCollector.kvmConfig.enabled }}
    - /var/log/pods/kvm-monitoring_*/monitoring/*.log
{{- end }}
    - /var/log/pods/logs_logs-*/*/*.log
    - /var/log/pods/logs_*
    - /var/log/pods/logs_fluent*/*/*.log
    - /var/log/pods/dns-recursor_unbound*/*/*.log
    - /var/log/pods/kube-system_wormhole*/*/*.log
  operators:
    - id: container-parser
      type: container
    - id: parser-containerd
      type: add
      field: resource["container.runtime"]
      value: "containerd"
    - id: container-label
      type: add
      field: attributes["log.type"]
      value: "containerd"
{{end}}

{{- define "containerd.transform" }}
transform/protocol:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["network.protocol.name"] != nil
      statements:
        - set(log.attributes["network.protocol.name"], ConvertCase(resource.attributes["network.protocol.name"], "lower"))
        - delete_key(resource.attributes, "network.protocol.name")

transform/ingress:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["app.label.name"] == "ingress-nginx"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{IP:client.address} %{NOTSPACE:client.ident} %{NOTSPACE:client.auth} \\[%{HTTPDATE:httpdate}\\] \"%{WORD:http.request.method} %{NOTSPACE:url.path} %{WORD:network.protocol.name}/%{NOTSPACE:network.protocol.version}\" %{NUMBER:http.response.status_code} %{NUMBER:http.response.body.size:int} %{QUOTEDSTRING} \"%{GREEDYDATA:user_agent.original}\" %{NUMBER:http.request.body.size:int} %{BASE10NUM:request.time:float}( \\[%{NOTSPACE:service}\\])? ?(\\[\\])? %{IP:server.address}\\:%{NUMBER:server.port} %{NUMBER:upstream_response_length:int} %{BASE10NUM:upstream_response_time:float} %{NOTSPACE:upstream_status} %{NOTSPACE:request.id}", true),"upsert")
        - set(log.attributes["network.protocol.name"], ConvertCase(log.attributes["network.protocol.name"], "lower")) where log.attributes["network.protocol.name"] != nil
        - set(log.attributes["config.parsed"], "ingress-nginx") where log.attributes["client.address"] != nil

transform/perses:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "perses"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "time=%{QUOTEDSTRING} level=%{WORD:log.level} msg=%{GREEDYDATA:msg}", true),"upsert")
        - set(log.attributes["config.parsed"], "perses")
{{ end }}

{{- define "containerd.pipeline" }}
logs/containerd:
  receivers: [file_log/containerd]
  processors: [k8s_attributes, attributes/cluster, transform/ingress, transform/protocol, transform/perses]
  exporters: [routing]
{{- end }}
