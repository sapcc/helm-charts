{{- define "orbitus_image" -}}
  {{- if not $.Values.orbitus.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registry }}/orbitus:{{ $.Values.orbitus.image_tag }}
  {{- end -}}
{{- end -}}

{{- define "envvars_for_database" }}
{{- $ctx := index . 0 }}
{{- $db := index . 1 }}
- name: ORBITUS_DB_USERNAME
  value: '{{ $db }}'
- name: ORBITUS_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $ctx.Release.Name }}-pguser-{{ $db }}'
      key: 'postgres-password'
- name: ORBITUS_DB_HOSTNAME
  value: "orbitus-postgresql.{{ $ctx.Release.Namespace }}.svc"
- name: ORBITUS_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
{{- end -}}
