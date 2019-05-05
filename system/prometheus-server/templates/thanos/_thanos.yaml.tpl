type: SWIFT
config:
  auth_url: {{ required ".Values.thanos.swiftStorageConfig.authURL missing" .Values.thanos.swiftStorageConfig.authURL | quote }}
  username: {{ required ".Values.thanos.swiftStorageConfig.userName missing" .Values.thanos.swiftStorageConfig.userName | quote }}
  user_domain_name: {{ required ".Values.thanos.swiftStorageConfig.userDomainName missing" .Values.thanos.swiftStorageConfig.userDomainName | quote }}
  password: {{ required ".Values.thanos.swiftStorageConfig.password missing" .Values.thanos.swiftStorageConfig.password | quote }}
  domain_name: {{ required ".Values.thanos.swiftStorageConfig.domainName missing" .Values.thanos.swiftStorageConfig.domainName | quote }}
  tenant_name: {{ required ".Values.thanos.swiftStorageConfig.tenantName missing" .Values.thanos.swiftStorageConfig.tenantName | quote }}
  region_name: {{ required ".Values.thanos.swiftStorageConfig.regionName missing" .Values.thanos.swiftStorageConfig.regionName | quote }}
  container_name: {{ required ".Values.thanos.swiftStorageConfig.containerName missing" .Values.thanos.swiftStorageConfig.containerName | quote }}
  {{ if .Values.thanos.swiftStorageConfig.userID }}
  user_id: {{ .Values.thanos.swiftStorageConfig.userID | quote }}
  {{ end }}
  {{ if .Values.thanos.swiftStorageConfig.domainID }}
  domain_id: {{ .Values.thanos.swiftStorageConfig.domainID | quote }}
  {{ end }}
  {{ if .Values.thanos.swiftStorageConfig.tenantID }}
  tenant_id: {{ .Values.thanos.swiftStorageConfig.tenantID | quote }}
  {{ end }}
