{{- if .Values.simulator.enabled -}}
simulator:
  prometheusPort: {{ .Values.simulator.prometheusPort }}
  testsJsonPath: {{ .Values.simulator.testsJsonPath }}
  region: {{ .Values.config.keystone.region }}
  enableTimer: {{ .Values.simulator.enableTimer }}
  smtpHost: {{ .Values.simulator.smtpHost }}
  smtpPort: {{ .Values.simulator.smtpPort }}
  sesUsername: {{ .Values.simulator.sesUsername }}
  sesApiEndpoint: {{ .Values.simulator.sesApiEndpoint }}
  nebulaApiEndpoint: {{ .Values.simulator.nebulaApiEndpoint }}
  pushgatewayUrl: {{ .Values.simulator.pushgatewayUrl }}
  sesRegion: {{ .Values.config.allowedServices.email }}
  metricName: {{ .Values.simulator.metricName }}
  metricHelp: {{ .Values.simulator.metricHelp }}
  cronuscli: {{ .Values.simulator.cronuscli }}
  recipient: {{ .Values.simulator.recipient }}
  sender: {{ .Values.simulator.sender }}
  shellToUse: {{ .Values.simulator.shellToUse }}
  slackMode: {{ .Values.simulator.slackMode }}
  slack: https://hooks.slack.com/services/{{ .Values.global.cronus_simulator_slack }}
  timeWaitInterval: {{ .Values.simulator.timeWaitInterval }}
  remote: {{ .Values.simulator.remote }}
  remoteRegion: {{ .Values.config.keystone.region }}
  cronus: {{ .Values.simulator.cronus }}
  nebula: {{ .Values.simulator.nebula }}
  delayTimeSeconds: {{ .Values.simulator.delayTimeSeconds }}
  tests:
  {{- range $key, $value := .Values.simulator.tests }}
    - {{ $value }}
  {{- end }}
  keystone:
      authUrl: {{ .Values.config.keystone.authUrl }}
      endpointType: {{ .Values.config.keystone.endpointType }}
      projectDomainName: {{ .Values.simulator.projectDomainName }}
      projectName: {{ .Values.simulator.projectName }}
      projectID: {{ .Values.simulator.projectID }}
      region: {{ .Values.config.keystone.region }}
      userDomainName: {{ .Values.config.keystone.userDomainName }}
      username: {{ .Values.config.keystone.username }}
{{- end }}
