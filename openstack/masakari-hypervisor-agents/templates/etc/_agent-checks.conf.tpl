url: https://masakari-monitoring.{{ .Values.global.region }}.cloud.sap/agent
interval: 5
timeout: 2
secret:
  value: {{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/masakari/monitoring-agent/secret" {{"}}"}}
