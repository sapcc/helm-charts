{{- define "pricelist_image" -}}
  {{- if not $.Values.pricelist.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registry }}/orbitus:{{ $.Values.pricelist.image_tag }}
  {{- end -}}
{{- end -}}

{{- define "pricelist_data_image" -}}
  {{- if not $.Values.pricelist.pricelist_data_image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registry }}/orbitus-pricelist-data:{{ $.Values.pricelist.pricelist_data_image_tag }}
  {{- end -}}
{{- end -}}

{{- define "pricelist_common_envvars" }}
- name: PRICELIST_DRYRUN
  value: {{ quote $.Values.pricelist.dryrun }}
- name: PRICELIST_REGIONS
  value: {{ quote $.Values.orbitus.regions }}
- name: PRICELIST_CONFIG_PATH
  value: /pricelist-data
- name: ORBITUS_OSLO_POLICY_PATH
  value: /etc/pricelist/policy.json
{{- end -}}
