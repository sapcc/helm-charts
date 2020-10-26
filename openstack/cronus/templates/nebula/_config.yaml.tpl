{{- if .Values.nebula.enabled -}}
nebula:
  cacheSize: {{ .Values.nebula.cacheSize }}
  listenAddr:
    http: :{{ .Values.nebula.port.http }} # default :1080
  keystone:
    authUrl: {{ .Values.config.authUrl }}
    applicationCredentialID: {{ .Values.config.keystone.applicationCredentialID }}
    applicationCredentialSecret: {{ .Values.config.keystone.applicationCredentialSecret }}
    applicationCredentialName: {{ .Values.config.keystone.applicationCredentialName }}
    projectID: {{ .Values.config.keystone.projectID }}
    projectName: {{ .Values.config.keystone.projectName }}
    projectDomainName: {{ .Values.config.keystone.projectDomainName }}
    projectDomainID: {{ .Values.config.keystone.projectDomainID }}
    userDomainName: {{ .Values.config.keystone.userDomainName }}
    domainName: {{ .Values.config.keystone.domainName }}
    domainID: {{ .Values.config.keystone.domainID }}
    username: {{ .Values.config.keystone.username }}
    password: {{ .Values.config.keystone.userID }}
    userID: {{ .Values.config.keystone.password }}
    region: {{ .Values.config.keystone.region }}
    endpointType: {{ .Values.config.keystone.endpointType }}
  serviceUser:
    username: {{ .Values.config.serviceUsername }}
    password: {{ .Values.config.servicePassword }}
  jira:
    username: {{ .Values.config.jiraUsername }}
    password: {{ .Values.config.jiraPassword }}
  group: {{ .Values.config.group }}
  technicalResponsible: {{ .Values.config.technicalResponsible }}
  aws:
    region: {{ .Values.config.allowedServices.email }}
    access: {{ .Values.config.awsAccess }}
    secret: {{ .Values.config.awsSecret }}
    technicalUsername: {{ .Values.config.technicalUsername }}
    policyName: {{ .Values.config.awsPolicy }}
    verifyEmailDomain: {{ .Values.config.verifyEmailDomain }}
    verifyEmailSecret: {{ .Values.config.verifyEmailSecret }}
  accountStatusPollDelay: {{ .Values.config.accountStatusPollDelay }}
  accountStatusTimeout: {{ .Values.config.accountStatusTimeout }}
  debug: {{ .Values.nebula.debug }}
{{- end -}}
