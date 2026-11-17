{{- define "pricelist_data_image" -}}
  {{- if not $.Values.pricelist.pricelist_data_image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registry }}/orbitus-pricelist-data:{{ $.Values.pricelist.pricelist_data_image_tag }}
  {{- end -}}
{{- end -}}

{{- define "pricelist_openstack_envvars" }}
{{- $regions := .Values.orbitus.regions | required "missing value for .Values.orbitus.regions" }}
{{- range $r := splitList "," $regions }}
{{- $r = trim $r }}
{{- $regionKey := $r | replace "-" "_" | upper }}
- name: OS_{{ $regionKey }}_AUTH_URL
  value: {{ printf "https://identity-3.%s.%s/v3" $r $.Values.global.tld | quote }}
- name: OS_{{ $regionKey }}_PASSWORD
  valueFrom:
    secretKeyRef:
      name: orbitus-secret
      key: os_password_{{ $regionKey }}
{{- end }}
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
