{{- if .Values.simulator.enabled -}}
simulator:
  cronuscli: {{ .Values.simulator.cronuscli }}
  recipient: {{ .Values.simulator.recipient }}
  shellToUse: {{ .Values.simulator.shellToUse }}
  slack: https://hooks.slack.com/services/{{ .Values.global.cronus_simulator_slack }}
  timeWaitInterval: {{ .Values.simulator.timeWaitInterval }}
  remote: {{ .Values.simulator.remote }}
  remoteRegion: {{ .Values.simulator.remoteRegion }}
  remotePassword: {{ .Values.simulator.remotePassword }}
  cronus: {{ .Values.simulator.cronus }}
  nebula: {{ .Values.simulator.nebula }}
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