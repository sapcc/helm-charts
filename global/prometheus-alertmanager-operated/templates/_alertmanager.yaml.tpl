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

{{- range tuple "ap-ae-1" "ap-au-1" "ap-cn-1" "ap-jp-1" "ap-jp-2" "ap-sa-1" "ap-sa-2" "eu-de-1" "eu-de-2" "eu-nl-1" "la-br-1" "na-ca-1" "na-us-1" "na-us-2" "na-us-3" "qa-de-1" }}
  - source_matchers:
      - alertname = "OpenstackKeppelDown"
      - region = "{{ . }}"
    target_matchers:
      - alertname = "OpenstackKeppelAnycastDown"
      - meta = "Keppel anycast health check failing for healthcheck-{{ . }}"

  - source_matchers:
      - alertname =~ "OpenstackKeppelDown"
      - region = "{{ . }}"
    target_matchers:
      - alertname = "OpenstackKeppelSlowPeering"
      - meta = "Keppel cannot peer with keppel.{{ . }}.cloud.sap"
{{- end }}

route:
  group_by: ['region', 'service', 'alertname', 'cluster', 'support_group']
  group_wait: 1m
  group_interval: 7m
  repeat_interval: 12h
  receiver: elastic

  routes:
  - receiver: elastic
    continue: true

  {{- if .Values.cc_email_receiver.enabled }}
  - receiver: cc_email_receiver
    group_by: ['...']
    continue: false
    matchers: [alertname="KubernikusKlusterLowOnObjectStoreQuota",primary_email_recipients!=""]
  {{- end }}


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

  - receiver: awx
    continue: true
    match_re:
      tier: vmware

  # review for slack_by_cc_service
  - receiver: slack_cc-cp
    continue: true
    match_re:
      severity: info|warning|critical
      service: cc-cp

  - receiver: slack_by_k8s_service
    continue: true
    match_re:
      tier: k8s
      severity: info|warning|critical
      service: vault
      region: qa-de-1|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_by_os_service
    continue: true
    match_re:
      tier: os
      severity: info|warning|critical
      service: arc|barbican|cinder|cronus|designate|documentation|elektra|elk|glance|ironic|lyra|manila|neutron|nova|octavia|placement|sentry|snmp
      region: qa-de-1|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_by_cc_service
    continue: true
    match_re:
      severity: info|warning|critical
      service: alerting|backup|castellum|cc3test|exporter|gatekeeper|grafana|hermes|jumpserver|keppel|limes|logs|maia|metis|metrics|repo|slack-alert-reactions|swift|tenso
      region: qa-de-1|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  # to be reviewed
  - receiver: slack_sre
    continue: false
    match_re:
      context: sre

  - receiver: octobus
    continue: true
    match_re:
      severity: info|warning|critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  # to be reviewed
  - receiver: slack_storage
    continue: false
    match_re:
      tier: storage

  # review for slack_by_cc_service
  - receiver: slack_wsus
    continue: true
    match_re:
      service: wsus

  - receiver: support_group_alerts_critical_compute
    continue: true
    match_re:
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: compute

  - receiver: support_group_alerts_critical_compute_storage_api
    continue: true
    match_re:
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: compute-storage-api

  - receiver: support_group_alerts_critical_containers
    continue: true
    match_re:
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: containers

  - receiver: support_group_alerts_critical_email
    continue: true
    match_re:
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: email

  - receiver: support_group_alerts_critical_identity
    continue: true
    match_re:
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: identity

  - receiver: support_group_alerts_critical_foundation
    continue: true
    match_re:
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: foundation

  - receiver: support_group_alerts_critical_network_api
    continue: true
    match_re:
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: network-api

  - receiver: support_group_alerts_critical_observability
    continue: true
    match_re:
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: observability

  - receiver: support_group_alerts_critical
    continue: true
    match_re:
      severity: critical
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: src|network-data|network-security|network-lb|network-wan|storage

  - receiver: support_group_alerts_warning
    continue: true
    match_re:
      severity: warning
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: compute|compute-storage-api|containers|email|identity|foundation|network-api|observability|src|network-data|network-security|network-lb|network-wan|storage

  - receiver: support_group_alerts_info
    continue: true
    match_re:
      severity: info
      cluster_type: abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
      support_group: foundation

  - receiver: support_group_alerts_qa
    continue: true
    match_re:
      severity: warning|critical
      region: qa-de-1
      support_group: compute|compute-storage-api|containers|email|identity|foundation|network-api|observability|src|network-data|network-security|network-lb|network-wan|storage

  - receiver: support_group_alerts_labs
    continue: true
    match_re:
      severity: warning|critical
      region: qa-de-2|qa-de-3|qa-de-4|qa-de-5|qa-de-6
      support_group: compute|compute-storage-api|containers|email|identity|foundation|network-api|observability|src|network-data|network-security|network-lb|network-wan|storage

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

   # sunset
  - receiver: slack_metal_critical
    continue: false
    match_re:
      tier: metal
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1|qa-de-2|qa-de-3|qa-de-5

  # sunset
  - receiver: slack_metal_warning
    continue: false
    match_re:
      tier: metal
      severity: warning
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1|qa-de-2|qa-de-3|qa-de-5
  # sunset
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

  # rework to match support group compute needed
  - receiver: slack_vmware_critical
    continue: false
    match_re:
      tier: vmware
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
  # rework to match support group compute needed
  - receiver: slack_vmware_warning
    continue: false
    match_re:
      tier: vmware
      severity: warning
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
  # rework to match support group compute needed
  - receiver: slack_vmware_info
    continue: false
    match_re:
      tier: vmware
      severity: info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  # sunset - network-data | network-security | network-lb | network-wan
  - receiver: slack_net_critical
    continue: true
    match_re:
      tier: net
      severity: critical
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  # sunset - network-data | network-security | network-lb | network-wan
  - receiver: slack_net_warning
    continue: false
    match_re:
      tier: net
      severity: warning
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  # sunset - network-data | network-security | network-lb | network-wan
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

receivers:
  - name: wham_metal
    webhook_configs:
      - url: "https://wham.scaleout.eu-de-1.cloud.sap/alerts/metal"

  - name: elastic
    webhook_configs:
    - send_resolved: true
      url: {{ required ".Values.elastic.logstashURL undefined" .Values.elastic.logstashURL | quote }}

  - name: octobus
    webhook_configs:
    #- send_resolved: true
    #  url: {{ required ".Values.octobus.gymInstance undefined" .Values.octobus.gymInstance | quote }}
    - send_resolved: true
      url: {{ required ".Values.octobus.gcpInstance undefined" .Values.octobus.gcpInstance | quote }}

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

  - name: support_group_alerts_critical_compute
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.compute.criticalWebhookURL undefined" .Values.slack.compute.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: support_group_alerts_critical_compute_storage_api
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.compute_storage_api.criticalWebhookURL undefined" .Values.slack.compute_storage_api.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: support_group_alerts_critical_email
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.email.criticalWebhookURL undefined" .Values.slack.email.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: support_group_alerts_critical_identity
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.identity.criticalWebhookURL undefined" .Values.slack.identity.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: support_group_alerts_critical_foundation
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.foundation.criticalWebhookURL undefined" .Values.slack.foundation.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: support_group_alerts_critical_network_api
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.network_api.criticalWebhookURL undefined" .Values.slack.network_api.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: support_group_alerts_critical_observability
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.observability.criticalWebhookURL undefined" .Values.slack.observability.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: support_group_alerts_critical
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

  - name: support_group_alerts_critical_containers
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-{{"{{ .CommonLabels.severity }}"}}'
        api_url: {{ required ".Values.slack.containers.criticalWebhookURL undefined" .Values.slack.containers.criticalWebhookURL | quote }}
        username: "Pulsar"
        title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
        title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
        text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
        pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
        icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
        callback_id: "alertmanager"
        color: {{`'{{template "slack.sapcc.color" . }}'`}}
        send_resolved: true

  - name: support_group_alerts_warning
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

  - name: support_group_alerts_info
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

  - name: support_group_alerts_labs
    slack_configs:
      - channel: '#alert-{{"{{ .CommonLabels.support_group }}"}}-labs'
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

  # email receiver config
  {{- if .Values.cc_email_receiver.enabled }}
  - name: cc_email_receiver
    email_configs:
      - to: {{"'{{.CommonLabels.primary_email_recipients}},{{.CommonLabels.cc_email_recipients}},{{.CommonLabels.bcc_email_recipients}}'"}}
        from: {{ required ".Values.cc_email_receiver.email_from_address undefined" .Values.cc_email_receiver.email_from_address | quote }}
        headers:
          subject: {{"'{{ .CommonAnnotations.mail_subject }}'"}}
          To: {{"'{{.CommonLabels.primary_email_recipients}}'"}}
          CC: {{"'{{.CommonLabels.cc_email_recipients}}'"}}
        text: {{"'{{ .CommonAnnotations.mail_body }}'"}}
        html: {{"'{{ template \"cc_email_receiver.KubernikusKlusterLowOnObjectStoreQuota\" . }}'"}}
        smarthost: {{ required ".Values.cc_email_receiver.smtp_host undefined" .Values.cc_email_receiver.smtp_host | quote }}
        auth_username: {{ required ".Values.cc_email_receiver.auth_username undefined" .Values.cc_email_receiver.auth_username | quote }}
        auth_password: {{ required ".Values.cc_email_receiver.auth_password undefined" .Values.cc_email_receiver.auth_password | quote }}
        require_tls: true
        send_resolved: false
  {{- end }}
