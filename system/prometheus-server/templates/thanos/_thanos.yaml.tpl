type: SWIFT
config:
  auth_url: {{ required ".Values.thanos.swiftStorageConfig.authURL missing" .Values.thanos.swiftStorageConfig.authURL | quote }}
  username: {{ required ".Values.thanos.swiftStorageConfig.userName missing" .Values.thanos.swiftStorageConfig.userName | quote }}
  user_domain_name: {{ required ".Values.thanos.swiftStorageConfig.userDomainName missing" .Values.thanos.swiftStorageConfig.userDomainName | quote }}
  password: {{ required ".Values.thanos.swiftStorageConfig.password missing" .Values.thanos.swiftStorageConfig.password | quote }}
  project_name: {{ required ".Values.thanos.swiftStorageConfig.projectName missing" .Values.thanos.swiftStorageConfig.projectName | quote }}
  project_domain_name: {{ required ".Values.thanos.swiftStorageConfig.projectDomainName missing" .Values.thanos.swiftStorageConfig.projectDomainName | quote }}
  region_name: {{ required ".Values.thanos.swiftStorageConfig.regionName missing" .Values.thanos.swiftStorageConfig.regionName | quote }}
  container_name: {{ required ".Values.thanos.swiftStorageConfig.containerName missing" .Values.thanos.swiftStorageConfig.containerName | quote }}
