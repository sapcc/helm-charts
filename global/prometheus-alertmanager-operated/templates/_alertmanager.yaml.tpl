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

  # If the alert NodeInMaintenance is firing other alerts with the label inhibited-by: node-maintenance are being inhibited on the same node.
  - source_match:
      alertname: NodeInMaintenance
    target_match:
      inhibited_by: node-maintenance
    equal: ['node']

route:
  group_by: ['region', 'service', 'alertname', 'cluster', 'support_group']
  group_wait: 1m
  group_interval: 7m
  repeat_interval: 12h
  receiver: dev-null

  routes:
  # review for slack_by_cc_service
  - receiver: slack_hsm
    continue: false
    match_re:
      service: barbican
      context: hsm
      severity: info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1

  # review for slack_by_cc_service
  - receiver: slack_barbican_certificate
    continue: false
    match_re:
      service: barbican
      context: certificate
      severity: info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1

  # review for slack_by_cc_service
  - receiver: slack_nannies
    continue: false
    match_re:
      context: nanny
      severity: critical|warning|info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  # review for slack_by_cc_service
  - receiver: slack_nannies_automation
    continue: false
    match_re:
      context: nanny-automation
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_k8s
    continue: true
    match_re:
      tier: k8s
      severity: critical|warning|info
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: qa-de-1|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_kks_default
    continue: true
    match_re:
      tier: kks
      severity: warning|info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_kks_critical
    continue: true
    match_re:
      tier: kks
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_concourse
    continue: true
    match_re:
      severity: info|warning|critical
      service: concourse

  # review for slack_by_cc_service
  - receiver: slack_cc-cp
    continue: true
    match_re:
      severity: info|warning|critical
      service: cc-cp

  # deprecated
  - receiver: pagerduty_alertchain_test
    continue: false
    match_re:
      tier: test-tier
      region: area51

  - receiver: slack_by_k8s_service
    continue: true
    match_re:
      tier: k8s
      severity: info|warning|critical
      service: gatekeeper|vault
      region: qa-de-1|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_by_os_service
    continue: true
    match_re:
      tier: os
      severity: info|warning|critical
      # NOTE: Please keep this list in sync with the identical list in `system/gatekeeper-config/values.yaml`.
      service: arc|backup|barbican|castellum|cinder|cfm|cronus|designate|documentation|elektra|elk|glance|ironic|keppel|limes|lyra|manila|neutron|nova|octavia|placement|sentry|swift|snmp|tenso
      region: qa-de-1|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_by_cc_service
    continue: true
    match_re:
      severity: info|warning|critical
      service: alerting|cc3test|exporter|grafana|hermes|jumpserver|maia|metis|metrics|logs
      region: qa-de-1|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_sre
    continue: false
    match_re:
      context: sre

  # deprecated
  - receiver: slack_monitoring
    continue: false
    match_re:
      tier: monitor
      severity: critical|warning|info

  - receiver: elastic
    continue: true

  - receiver: octobus
    continue: true
    match_re:
      severity: info|warning|critical
      tier: metal|net|vmware|os|k8s|kks
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_storage
    continue: false
    match_re:
      tier: storage

  # deprecated
  - receiver: dev-null
    continue: false
    match_re:
      cluster: k-master

  # review for slack_by_cc_service
  - receiver: slack_wsus
    continue: true
    match_re:
      service: wsus

  - receiver: support_group_alerts
    continue: true
    match_re:
      severity: warning|critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: compute|compute-storage-api|containers|email|identity|network-api|observability

  - receiver: support_group_alerts_qa
    continue: true
    match_re:
      severity: warning|critical
      region: qa-de-1|qa-de-2|qa-de-3|qa-de-5
      support_group: compute|compute-storage-api|containers|email|identity|network-api|observability
  # sunset latest q1-23
  - receiver: pagerduty_api
    continue: true
    match_re:
      tier: os|k8s|kks
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
  # sunset latest q1-23
  - receiver: slack_api_critical
    continue: false
    match_re:
      tier: os|k8s|kks
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_api_warning
    continue: false
    match_re:
      tier: os|k8s|kks
      severity: warning
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
  # sunset latest q1-23
  - receiver: slack_api_info
    continue: false
    match_re:
      tier: os|k8s|kks
      severity: info
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
  # sunset latest q1-23
  - receiver: pagerduty_metal
    continue: true
    match_re:
      tier: metal
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1|qa-de-2|qa-de-3|qa-de-5
  # sunset latest q1-23
  - receiver: slack_metal_critical
    continue: false
    match_re:
      tier: metal
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1|qa-de-2|qa-de-3|qa-de-5

  # sunset latest q1-23
  - receiver: slack_metal_warning
    continue: false
    match_re:
      tier: metal
      severity: warning
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1|qa-de-2|qa-de-3|qa-de-5
  # sunset latest q1-23
  - receiver: slack_metal_info
    continue: false
    match_re:
      tier: metal
      severity: info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1|qa-de-2|qa-de-3|qa-de-5

  - receiver: slack_ad_warning
    continue: false
    match_re:
      tier: ad
      severity: warning
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1

  - receiver: slack_ad_info
    continue: false
    match_re:
      tier: ad
      severity: info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1
  # sunset latest q1-23
  - receiver: pagerduty_vmware
    continue: true
    match_re:
      tier: vmware
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
  # sunset latest q1-23
  - receiver: slack_vmware_critical
    continue: false
    match_re:
      tier: vmware
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
  # sunset latest q1-23
  - receiver: slack_vmware_warning
    continue: false
    match_re:
      tier: vmware
      severity: warning
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
  # sunset latest q1-23
  - receiver: slack_vmware_info
    continue: false
    match_re:
      tier: vmware
      severity: info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_net_critical
    continue: true
    match_re:
      tier: net
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: pagerduty_network_cisco
    continue: false
    match_re:
      tier: net
      severity: critical
      module: acispine|acileaf|acistretch
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: pagerduty_network_apic_exporter
    continue: false
    match_re:
      tier: net
      severity: critical
      app: apic-exporter
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: pagerduty_network
    continue: false
    match_re:
      tier: net
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_net_warning
    continue: false
    match_re:
      tier: net
      severity: warning
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_net_info
    continue: false
    match_re:
      tier: net
      severity: info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  # sunset latest q1-23
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

  - name: octobus
    webhook_configs:
    - send_resolved: true
      url: {{ required ".Values.octobus.gymInstance undefined" .Values.octobus.gymInstance | quote }}
    - send_resolved: true
      url: {{ required ".Values.octobus.gcpInstance undefined" .Values.octobus.gcpInstance | quote }}

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

  - name: slack_ad_info
    slack_configs:
      - channel: '#alert-ad-info'
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

  - name: slack_ad_warning
    slack_configs:
      - channel: '#alert-ad-warning'
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

  - name: slack_by_k8s_service
    slack_configs:
      - channel: '#cc-k8s-{{"{{ .CommonLabels.service }}"}}'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
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
  - name: slack_by_cc_service
    slack_configs:
      - channel: '#cc-{{"{{ .CommonLabels.service }}"}}'
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

  - name: slack_cc-cp
    slack_configs:
      - channel: '#cc-cp'
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

  - name: slack_nannies_automation
    slack_configs:
      - channel: '#cc-nannies-automation'
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

  - name: slack_wsus
    slack_configs:
      - channel: '#cc-wsus'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_barbican_certificate
    slack_configs:
      - channel: '#cc-os-barbican-cert-expiry'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: slack_hsm
    slack_configs:
      - channel: '#cc-os-hsm'
        api_url: {{ required ".Values.slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: support_group_alerts
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-{{"{{ .CommonLabels.severity }}"}}'
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

  - name: support_group_alerts_qa
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-qa'
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
      - service_key: {{ required ".Values.pagerduty_sap.osd_mom_compute.serviceKey undefined" .Values.pagerduty_sap.osd_mom_compute.serviceKey | quote }}
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
      - service_key: {{ required ".Values.pagerduty_sap.osd_mom_network.serviceKey undefined" .Values.pagerduty_sap.osd_mom_network.serviceKey | quote }}
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

  - name: pagerduty_network_cisco
    pagerduty_configs:
      - service_key: {{ required ".Values.pagerduty_sap.network.serviceKeyCsm undefined" .Values.pagerduty_sap.network.serviceKeyCsm | quote }}
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
      - service_key: {{ required ".Values.pagerduty_sap.osd_mom_network.serviceKey undefined" .Values.pagerduty_sap.osd_mom_network.serviceKey | quote }}
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

  - name: pagerduty_network_apic_exporter
    pagerduty_configs:
      - service_key: {{ required ".Values.pagerduty_sap.network.serviceKeyCsm undefined" .Values.pagerduty_sap.network.serviceKeyCsm | quote }}
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
      - service_key: {{ required ".Values.pagerduty_sap.osd_mom_network.serviceKey undefined" .Values.pagerduty_sap.osd_mom_network.serviceKey | quote }}
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
      - service_key: {{ required ".Values.pagerduty_sap.osd_mom_compute.serviceKey undefined" .Values.pagerduty_sap.osd_mom_compute.serviceKey | quote }}
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
