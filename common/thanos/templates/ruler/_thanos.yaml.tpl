{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
type: SWIFT
config:
  auth_url: "https://identity-3.{{ $root.Values.global.region }}.cloud.sap/v3"
  username: "prometheus-kubernetes-{{ $name }}-thanos"
  domain_name: "Default"
  password: {{ printf "{{ resolve `vault+kvv2:///secrets/%s/thanos-greenhouse/keystone-user/prometheus-kubernetes-thanos/password` }}" $root.Values.global.region }}
  project_name: "master"
  project_domain_name: "ccadmin"
  region_name: {{ $root.Values.global.region | quote }}
  container_name: "prometheus-kubernetes-{{ $name }}-thanos"
