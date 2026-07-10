{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- $name := ternary "metal" $host (has $host (list "global" "regional")) -}}
type: SWIFT
config:
  auth_url: "https://identity-3.{{ $root.Values.global.region }}.cloud.sap/v3"
  username: "prometheus-kubernetes-{{ $name }}-thanos"
  domain_name: "Default"
  password: "vault+kvv2:///secrets/{{ $root.Values.global.region }}/thanos-greenhouse/keystone-user/prometheus-kubernetes-thanos/password"
  project_name: "master"
  project_domain_name: "ccadmin"
  region_name: {{ $root.Values.global.region | quote }}
  container_name: "prometheus-kubernetes-{{ $name }}-thanos"
