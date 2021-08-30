{{- if .Values.simulator.enabled -}}
simulator:
{{- if .Values.simulator.smtpInfo }}
  smtpInfo:
    host: {{ .Values.simulator.smtpInfo.host }}
    port: {{ .Values.simulator.smtpInfo.port }}
    smtpUsername: {{ .Values.simulator.smtpInfo.smtpUsername }}
    smtpPassword: {{ .Values.simulator.smtpInfo.smtpPassword }}
    insecureSkipVerify: {{ .Values.simulator.smtpInfo.insecureSkipVerify }}
{{- end }}
  cronuscli: {{ .Values.simulator.cronuscli }}
  recipient: {{ .Values.simulator.recipient }}
  sender: {{ .Values.simulator.sender }}
  shellToUse: {{ .Values.simulator.shellToUse }}
  slackMode: {{ .Values.simulator.slackMode }}
  slack: https://hooks.slack.com/services/{{ .Values.global.cronus_simulator_slack }}
  timeWaitInterval: {{ .Values.cross.timeWaitInterval }}
  remote: {{ .Values.simulator.remote }}
  remoteRegion: {{ .Values.config.keystone.region }}
  remotePassword: {{ .Values.global.cronus_service_password }}
  cronus: {{ .Values.simulator.cronus }}
  nebula: {{ .Values.simulator.nebula }}
  delayTimeSeconds: {{ .Values.simulator.delayTimeSeconds }}
  pushgatewayUrl: {{ .Values.exporter.pushgatewayUrl }}
  keystone:
      authUrl: {{ .Values.config.keystone.authUrl }}
      endpointType: {{ .Values.config.keystone.endpointType }}
      projectDomainName: {{ .Values.simulator.projectDomainName }}
      projectName: {{ .Values.simulator.projectName }}
      region: {{ .Values.config.keystone.region }}
      userDomainName: {{ .Values.config.keystone.userDomainName }}
      username: {{ .Values.config.keystone.username }}
      password: {{ .Values.global.cronus_service_password }}
{{- end }}