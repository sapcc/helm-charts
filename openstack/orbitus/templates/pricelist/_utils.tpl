{{- define "pricelist_image" -}}
  {{- if contains "DEFINED" $.Values.pricelist.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registry }}/orbitus:{{ $.Values.pricelist.image_tag }}
  {{- end -}}
{{- end -}}

{{- define "pricelist_data_image" -}}
  {{- if contains "DEFINED" $.Values.pricelist.pricelist_data_image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registry }}/orbitus-pricelist-data:{{ $.Values.pricelist.pricelist_data_image_tag }}
  {{- end -}}
{{- end -}}

{{- define "pricelist_common_envvars" }}
- name: PRICELIST_DRYRUN
  value: {{ quote $.Values.pricelist.dryrun }}
- name: PRICELIST_REGIONS
  value: {{ quote $.Values.global.region }}
- name: PRICELIST_CONFIG_PATH
  value: /pricelist-data
- name: ORBITUS_OSLO_POLICY_PATH
  value: /etc/pricelist/policy.json
{{- end -}}


{{- define "pricelist_db_envvars" }}
- name: ORBITUS_DB_USERNAME
  value: 'pricelist'
- name: ORBITUS_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $.Release.Name }}-pguser-pricelist'
      key: 'postgres-password'
- name: ORBITUS_DB_HOSTNAME
  value: "orbitus-postgresql.{{ .Release.Namespace }}.svc"
- name: ORBITUS_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
{{- end -}}

{{/*
  The pricelist init container copies the region-specific pricelist out of the data image into the shared
  emptyDir. The main container reads from: /pricelist-data/pricelist.json.gz
*/}}
{{- define "pricelist_init_container" }}
- name: pricelist-loader
  image: {{ include "pricelist_data_image" . }}
  imagePullPolicy: IfNotPresent
  command: [ /bin/sh ]
  args:
    - '-c'
    - |
      set -euo pipefail
      cp /pricelist/{{ .Values.global.region }}/pricelist.json.gz /pricelist-out/pricelist.json.gz
  volumeMounts:
    - mountPath: /pricelist-out
      name: pricelist-data
{{- end -}}
