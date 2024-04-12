{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
type: SWIFT
config:
  auth_url: {{ required "$root.Values.thanosSeeds.swiftStorageConfig.authURL missing" $root.Values.thanosSeeds.swiftStorageConfig.authURL | quote }}
  username: {{ include "swift.userName" (list $name $root) }}
  domain_name: {{ required "$root.Values.thanosSeeds.swiftStorageConfig.userDomainName missing" $root.Values.thanosSeeds.swiftStorageConfig.userDomainName | quote }}
  password: "{{ required "$root.Values.thanosSeeds.swiftStorageConfig.password missing" $root.Values.thanosSeeds.swiftStorageConfig.password }}"
  project_name: {{ include "thanos.projectName" $root }}
  project_domain_name: {{ include "thanos.projectDomainName" $root }}
  region_name: {{ required "$root.Values.global.region missing" $root.Values.global.region }}
  container_name: {{ include "swift.containerName" (list $name $root) }}
  {{ if $root.Values.thanosSeeds.swiftStorageConfig.projectDomainName }}
  project_domain_name: {{ $root.Values.thanosSeeds.swiftStorageConfig.projectDomainName | quote }}
  {{ end }}
