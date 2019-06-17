When passed via `helm upgrade --set`, the image tag is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "image_version" -}}
  {{- if typeIs "string" $.Values.image_version -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .Values.image_version -}}
      {{$.Values.image_version | printf "%0.f"}}
    {{- else -}}
      {{$.Values.image_version}}
    {{- end -}}
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
