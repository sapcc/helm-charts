chroot: /coreos

drives:
  - {{.Values.swift_drive_autopilot.drive_glob}}

# the Swift user and group is UID/GID 1000 in the Kolla containers
chown:
  user: "1000"
  group: "1000"

{{ if .Values.swift_drive_autopilot.encryption_key }}
keys:
  - secret: {{.Values.swift_drive_autopilot.encryption_key}}
{{ end }}

{{ if .Values.swift_drive_autopilot.drive_count }}
{{ $cnt := int .Values.swift_drive_autopilot.drive_count }}
swift-id-pool: {{ range $idx := until $cnt }}
  - swift-{{ $idx | add1 | printf "%02d" }}
{{ end }}
{{ end }}
