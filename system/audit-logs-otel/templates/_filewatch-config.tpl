{{- define "filewatch.receiver" }}
receivers:
  filewatch:
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
{{ end }}
{{- define "filewatch.attributes" }}
attributes/filewatch:
  actions:
    - action: insert
      key: log.type
      value: "filewatch"
{{- end }}
