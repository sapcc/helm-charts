{{- if .Values.simulator.enabled -}}
simulator:
  cronuscli: {{ .Values.simulator.cronuscli }}
  recipient: {{ .Values.simulator.recipient }}
  shellToUse: {{ .Values.simulator.shellToUse }}
  slack: {{ .Values.simulator.slack }}
  timeWaitInterval: {{ .Values.simulator.timeWaitInterval }}
  keystone:
      authUrl: {{ .Values.config.keystone.authUrl }}
      endpointType: {{ .Values.config.keystone.endpointType }}
      projectDomainName: {{ .Values.simulator.projectDomainName }}
      projectName: {{ .Values.simulator.projectName }}
      region: {{ .Values.config.keystone.region }}
      userDomainName: {{ .Values.config.keystone.userDomainName }}
      username: {{ .Values.config.keystone.username }}
      {{- if .Values.global.cronus_service_password }}
      password: {{ .Values.global.cronus_service_password }}
      {{- end }}
{{- end }}