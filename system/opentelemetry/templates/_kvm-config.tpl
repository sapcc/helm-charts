{{- define "kvm.labels" }}

{{- end }}
{{- define "kvm.receiver" }}
filelog/kvm_logs:
  include: [ /var/log/libvirt/qemu/*.log, /var/log/openvswitch/*.log ]
  include_file_path: true
  start_at: beginning
  multiline:
    line_start_pattern: ^\d{4}-\d{2}-\d{2}
  operators:
    - type: regex_parser
      regex: (?P<logtime>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3})
    - type: time_parser
      parse_from: attributes.logtime
      layout: '%Y-%m-%dT%H:%M:%S.%L'
      layout_type: strptime
    - id: file-label
      type: add
      field: attributes["log.type"]
      value: "files"
{{- end }}
{{- define "kvm.transform" }}
transform/kvm_openvswitch:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.daemonset.name"] == "neutron-openvswitch-agent"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{TIMESTAMP_ISO8601:logtime}%{SPACE}%{NUMBER:process.id}%{SPACE}%{WORD:log_level}%{SPACE}%{NOTSPACE:process.name}%{SPACE}\\[%{REQUEST_ID:request.id}%{SPACE}%{REQUEST_ID:request.global_id}", true, ["REQUEST_ID=([A-Za-z0-9-]+)"]), "upsert")
        - set(attributes["config.parsed"], "kvm_openvswitch") where attributes["log_level"] != nil

transform/kvm_nova_agent:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.daemonset.name"] == "nova-hypervisor-agents-compute-kvm"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{TIMESTAMP_ISO8601:logtime}%{SPACE}%{NUMBER:process.id}%{SPACE}%{WORD:log_level}%{SPACE}%{NOTSPACE:process.name}%{SPACE}\\[%{REQUEST_ID:request.id}%{SPACE}%{REQUEST_ID:request.global_id}", true, ["REQUEST_ID=([A-Za-z0-9-]+)"]), "upsert")
        - set(attributes["config.parsed"], "kvm_nova_agent") where attributes["log_level"] != nil

transform/kvm_logs:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["log.type"] == "files"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{TIMESTAMP_ISO8601:timestamp}%{SPACE}%{GREEDYDATA:log}",true), "upsert")
        - set(attributes["config.parsed"], "files") where attributes["log_level"]

{{- end }}
{{- define "kvm.pipeline" }}
logs/kvm_containerd:
  receivers: [filelog/containerd]
  processors: [k8sattributes,attributes/cluster,transform/ingress,transform/kvm_openvswitch,transform/kvm_nova_agent]
  exporters: [forward]
logs/kvm_filelog:
  receivers: [filelog/kvm_logs]
  processors: [k8sattributes,attributes/cluster,transform/kvm_logs]
  exporters: [forward]
{{- end }}
