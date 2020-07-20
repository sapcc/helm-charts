global:
  resolve_timeout: 16m

templates:
  - /notification-templates/*.tmpl

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['region', 'alertname', 'cluster']

  - source_match_re:
      severity: 'critical|warning'
    target_match:
      severity: 'info'
    equal: ['region', 'alertname', 'cluster']

  - source_match_re:
      severity: 'critical'
      context: '.+'
    target_match_re:
      severity: 'warning'
      context: '.+'
    equal: ['region', 'context', 'cluster']

  - source_match_re:
      severity: 'critical|warning'
      context: '.+'
    target_match_re:
      severity: 'info'
      context: '.+'
    equal: ['region', 'context', 'cluster']

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
  - receiver: slack_nannies
    continue: false
    match_re:
      context: nanny
      severity: critical|warning|info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_snmp
    continue: true
    match_re:
      context: snmp

  - receiver: slack_k8s
    continue: true
    match_re:
      tier: k8s
      severity: critical|warning|info
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: admin|qa-de-1|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_kks_default
    continue: true
    match_re:
      tier: kks
      severity: warning|info
      region: admin|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_kks_critical
    continue: true
    match_re:
      tier: kks
      severity: critical
      region: admin|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_concourse
    continue: true
    match_re:
      severity: info|warning|critical
      service: concourse

  - receiver: pagerduty_alertchain_test
    continue: false
    match_re:
      tier: test-tier
      region: area51

  - receiver: slack_by_os_service
    continue: true
    match_re:
      tier: os
      severity: info|warning|critical
      service: arc|backup|barbican|castellum|cinder|cfm|designate|elektra|elk|glance|hermes|ironic|keppel|keystone|limes|lyra|maia|manila|neutron|nova|octavia|sentry|swift
      region: qa-de-1|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_sre
    continue: false
    match_re:
      tier: sre

  - receiver: slack_monitoring
    continue: false
    match_re:
      tier: monitor
      severity: critical|warning|info

  - receiver: elastic
    continue: true

  - receiver: awx
    continue: true
    match_re:
      tier: vmware

  - receiver: slack_storage
    continue: false
    match_re:
      tier: storage

  - receiver: dev-null
    continue: false
    match_re:
      cluster: k-master

  - receiver: pagerduty_api
    continue: true
    match_re:
      tier: os|k8s|kks
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: admin|global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_api_critical
    continue: false
    match_re:
      tier: os|k8s|kks
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: admin|global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_api_warning
    continue: false
    match_re:
      tier: os|k8s|kks
      severity: warning
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: admin|global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_api_info
    continue: false
    match_re:
      tier: os|k8s|kks
      severity: info
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: admin|global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: pagerduty_metal
    continue: true
    match_re:
      tier: metal
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_metal_critical
    continue: false
    match_re:
      tier: metal
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_metal_warning
    continue: false
    match_re:
      tier: metal
      severity: warning
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_metal_info
    continue: false
    match_re:
      tier: metal
      severity: info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_vpod_critical
    continue: false
    match_re:
      tier: vpod
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_vpod_warning
    continue: false
    match_re:
      tier: vpod
      severity: warning
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_vpod_info
    continue: false
    match_re:
      tier: vpod
      severity: info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3


  - receiver: pagerduty_vmware
    continue: true
    match_re:
      tier: vmware
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_vmware_critical
    continue: false
    match_re:
      tier: vmware
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_vmware_warning
    continue: false
    match_re:
      tier: vmware
      severity: warning
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_vmware_info
    continue: false
    match_re:
      tier: vmware
      severity: info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: pagerduty_network
    continue: true
    match_re:
      tier: net
      severity: critical
      region: admin|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_net_critical
    continue: false
    match_re:
      tier: net
      severity: critical
      region: admin|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_net_warning
    continue: false
    match_re:
      tier: net
      severity: warning
      region: admin|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_net_info
    continue: false
    match_re:
      tier: net
      severity: info
      region: admin|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_qa
    continue: false
    match_re:
      severity: critical|warning|info
      region: qa-de-1

  - receiver: slack_dev
    continue: false
    match_re:
      severity: critical|warning|info
      region: staging|lab-1

  - receiver: wham_metal
    continue: false
    match_re:
      tier: metal
      severity: critical|warning|info
      region: qa-de-1|ap-jp-1|eu-ru-1

  - receiver: dev-null
    continue: false


receivers:
  - name: dev-null
    slack_configs:
      - api_url: {{ required "slack.devnullWebhookURL undefined" .Values.slack.devnullWebhookURL | quote }}
        username: "Pulsar"
        channel: "#dev-null"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: wham_metal
    webhook_configs:
      - url: "https://wham.scaleout.eu-de-1.cloud.sap/alerts/metal"

  - name: elastic
    webhook_configs:
    - send_resolved: true
      url: {{ required ".Values.elastic.logstashURL undefined" .Values.elastic.logstashURL | quote }}

  - name: awx
    webhook_configs:
    - send_resolved: true
      http_config:
        basic_auth:
          username: {{ required ".Values.awx.basicAuthUser undefined" .Values.awx.basicAuthUser | quote }}
          password: {{ required ".Values.awx.basicAuthPwd undefined" .Values.awx.basicAuthPwd | quote }}
      url: {{ required ".Values.awx.listenerURL undefined" .Values.awx.listenerURL | quote }}

  - name: slack_metal_info
    slack_configs:
      - channel: '#alert-metal-info'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_metal_warning
    slack_configs:
      - channel: '#alert-metal-warning'
        api_url: {{ required ".Values.slack.metal.warningWebhookURL undefined" .Values.slack.metal.warningWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_metal_critical
    slack_configs:
      - channel: '#alert-metal-critical'
        api_url: {{ required ".Values.slack.metal.criticalWebhookURL undefined" .Values.slack.metal.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_vpod_info
    slack_configs:
      - channel: '#alert-vpod-info'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_vpod_warning
    slack_configs:
      - channel: '#alert-vpod-warning'
        api_url: {{ required ".Values.slack.metal.warningWebhookURL undefined" .Values.slack.vpod.warningWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_vpod_critical
    slack_configs:
      - channel: '#alert-vpod-critical'
        api_url: {{ required ".Values.slack.metal.criticalWebhookURL undefined" .Values.slack.vpod.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_net_info
    slack_configs:
      - channel: '#alert-net-info'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_net_warning
    slack_configs:
      - channel: '#alert-net-warning'
        api_url: {{ required "slack.network.warningWebhookURL undefined" .Values.slack.network.warningWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_net_critical
    slack_configs:
      - channel: '#alert-net-critical'
        api_url: {{ required ".Values.slack.network.criticalWebhookURL undefined" .Values.slack.network.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_vmware_info
    slack_configs:
      - channel: '#alert-vmware-info'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_vmware_warning
    slack_configs:
      - channel: '#alert-vmware-warning'
        api_url: {{ required ".Values.slack.vmware.warningWebhookURL undefined" .Values.slack.vmware.warningWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_vmware_critical
    slack_configs:
      - channel: '#alert-vmware-critical'
        api_url: {{ required ".Values.slack.vmware.criticalWebhookURL undefined" .Values.slack.vmware.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_api_info
    slack_configs:
      - channel: '#alert-api-info'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_api_warning
    slack_configs:
      - channel: '#alert-api-warning'
        api_url: {{ required ".Values.slack.api.warningWebhookURL undefined" .Values.slack.api.warningWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_api_critical
    slack_configs:
      - channel: '#alert-api-critical'
        api_url: {{ required ".Values.slack.api.criticalWebhookURL undefined" .Values.slack.api.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_monitoring
    slack_configs:
      - channel: '#alert-moni-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_qa
    slack_configs:
      - channel: '#alert-qa-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_dev
    slack_configs:
      - channel: '#alert-dev-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_by_os_service
    slack_configs:
      - channel: '#cc-os-{{"{{ .CommonLabels.service }}"}}'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_k8s
    slack_configs:
      - channel: '#cc-k8s-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_kks_default
    slack_configs:
      - channel: '#cc-kks-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_kks_critical
    slack_configs:
      - channel: '#cc-kks-critical'
        api_url: {{ required ".Values.slack.kubernikus.criticalWebhookURL undefined" .Values.slack.kubernikus.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true
        actions:
          - name: {{"'{{template \"slack.sapcc.actionName\" . }}'"}}
            type: {{"'{{template \"slack.sapcc.actionType\" . }}'"}}
            text: {{"'{{template \"slack.sapcc.acknowledge.actionText\" . }}'"}}
            value: {{"'{{template \"slack.sapcc.acknowledge.actionValue\" . }}'"}}

  - name: slack_concourse
    slack_configs:
      - channel: '#cc-concourse'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_nannies
    slack_configs:
      - channel: '#cc-nannies'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_snmp
    slack_configs:
      - channel: '#cc-snmp'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_sre
    slack_configs:
      - channel: '#cc-sre'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_storage
    slack_configs:
      - channel: '#cc-storage'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: pagerduty_api
    pagerduty_configs:
      - service_key: {{ required ".Values.pagerduty_sap.api.serviceKey undefined" .Values.pagerduty_sap.api.serviceKey | quote }}
        description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
        component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        details:
          Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
          Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
          Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
          Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
          Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
          Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
          Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
          Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
          Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
          firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}

  - name: pagerduty_metal
    pagerduty_configs:
      - service_key: {{ required ".Values.pagerduty_sap.metal.serviceKey undefined" .Values.pagerduty_sap.metal.serviceKey | quote }}
        description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
        component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        details:
          Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
          Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
          Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
          Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
          Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
          Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
          Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
          Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
          Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
          firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}

  - name: pagerduty_network
    pagerduty_configs:
      - service_key: {{ required ".Values.pagerduty_sap.network.serviceKey undefined" .Values.pagerduty_sap.network.serviceKey | quote }}
        description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
        component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        details:
          Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
          Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
          Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
          Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
          Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
          Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
          Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
          Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
          Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
          firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}

  - name: pagerduty_vmware
    pagerduty_configs:
      - service_key: {{ required ".Values.pagerduty_sap.vmware.serviceKey undefined" .Values.pagerduty_sap.vmware.serviceKey | quote }}
        description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
        component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        details:
          Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
          Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
          Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
          Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
          Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
          Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
          Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
          Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
          Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
          firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}

  - name: pagerduty_alertchain_test
    pagerduty_configs:
      - service_key: {{ required ".Values.pagerduty_sap.alertTest.serviceKey undefined" .Values.pagerduty_sap.alertTest.serviceKey | quote }}
        description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
        component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        details:
          Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
          Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
          Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
          Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
          Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
          Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
          Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
          Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
          Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
          firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}
