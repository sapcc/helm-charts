{{- if .Values.exporter.enabled -}}
exporter:
  cronuscli: {{ .Values.exporter.cronuscli }}
  recipient: {{ .Values.exporter.recipient }}
  shellToUse: {{ .Values.exporter.shellToUse }}
  slack: https://hooks.slack.com/services/{{ .Values.global.cronus_exporter_slack }}
  timeWaitInterval: {{ .Values.exporter.timeWaitInterval }}
  keystone:
      authUrl: {{ .Values.config.keystone.authUrl }}
      endpointType: {{ .Values.config.keystone.endpointType }}
      projectDomainName: {{ .Values.exporter.projectDomainName }}
      projectName: {{ .Values.exporter.projectName }}
      region: {{ .Values.config.keystone.region }}
      userDomainName: {{ .Values.config.keystone.userDomainName }}
      username: {{ .Values.config.keystone.username }}
      {{- if .Values.global.cronus_service_password }}
      password: {{ .Values.global.cronus_service_password }}
      {{- end }}
{{- end }}