type: SWIFT
config:
  auth_url: {{ required ".Values.thanos.swiftStorageConfig.authURL missing" .Values.thanos.swiftStorageConfig.authURL | quote }}
  username: {{ include "swift.userName" . }}
  domain_name: {{ required ".Values.thanos.swiftStorageConfig.userDomainName missing" .Values.thanos.swiftStorageConfig.userDomainName | quote }}
  password: {{ required ".Values.thanos.swiftStorageConfig.password missing" .Values.thanos.swiftStorageConfig.password | quote }}
  project_name: {{ include "thanos.projectName" . }}
  project_domain_name: {{ include "thanos.projectDomainName" . }}
  region_name: {{ required ".Values.global.region missing" .Values.global.region }}
  container_name: {{ include "swift.userName" . }}
  {{ if .Values.thanos.swiftStorageConfig.projectDomainName }}
  project_domain_name: {{ .Values.thanos.swiftStorageConfig.projectDomainName | quote }}
  {{ end }}
