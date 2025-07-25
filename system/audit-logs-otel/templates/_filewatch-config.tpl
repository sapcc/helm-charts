{{- define "filewatch.receiver" }}
filewatch/audit_logs:
  include:
    - /hostfs/bin
    - /hostfs/usr/bin
    - /hostfs/sbin
    - /hostfs/usr/sbin
    - /hostfs/etc
  exclude:
    - '(?i)\.sw[nop]$'
    - '~$'
    - '/\.git($|/)'
  events:
    - "notify.InAccess"
    - "notify.InCreate"
    - "notify.InDelete"
    - "notify.InCloseWrite"

{{ end }}

{{- define "filewatch.processors" }}
attributes/filewatch:
  actions:
    - action: insert
      key: log.type
      value: "filewatch"
{{- end }}

{{- define "filewatch.pipelines" }}
logs/audit_filelog:
  receivers: [filewatch/audit_logs]
  processors: [attributes/filewatch,k8sattributes,attributes/cluster]
  exporters: [forward]
{{- end }}
