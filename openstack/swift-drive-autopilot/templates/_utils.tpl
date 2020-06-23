{{- define "image_version" -}}
  {{- if contains "DEFINED" $.Values.image_version -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.image_version}}
  {{- end -}}
{{- end -}}

{{- define "shared_config" }}
  chroot: /coreos
  metrics-listen-address: ":9102"

  # the Swift user and group is UID/GID 1000 in the Kolla containers
  chown:
    user: "1000"
    group: "1000"

  {{ if $.Values.encryption_key -}}
  keys:
    - secret: {{$.Values.encryption_key}}
  {{ end }}

  swift-id-pool: {{ range $idx := until 99 }}
    - swift-{{ printf "%02d" (add1 $idx) }}
    {{- if eq 0 (mod (add1 $idx) $.Values.one_spare_disk_every) }}
    - spare
    {{- end -}}
  {{ end -}}
{{- end -}}
