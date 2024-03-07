global:
  resolve_timeout: 16m

templates:
  - /etc/alertmanager/configmaps/alertmanager-cnmp-notification-templates/*.tmpl

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster']

  - source_match_re:
      severity: 'critical|warning'
    target_match:
      severity: 'info'
    equal: ['alertname', 'cluster']

  - source_match_re:
      severity: 'critical'
      context: '.+'
    target_match_re:
      severity: 'warning'
      context: '.+'
    equal: ['context', 'cluster']

  - source_match_re:
      severity: 'critical|warning'
      context: '.+'
    target_match_re:
      severity: 'info'
      context: '.+'
    equal: ['context', 'cluster']

  - source_match_re:
      alertname: '.*KubeletDown'
    target_match_re:
      alertname: 'PodNotReady|ManyPodsNotReadyOnNode'
    equal: ['node']

route:
  group_by: ['region', 'service', 'alertname', 'cluster']
  group_wait: 1m
  group_interval: 7m
  repeat_interval: 12h
  receiver: dev-null

  routes:
  - receiver: slack_cnmp


receivers:
  - name: slack_cnmp
    slack_configs:
      - channel: '#alert-cnmp'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "AlertManager"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: dev-null
    slack_configs:
      - api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "AlertManager"
        channel: "#dev-null"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
