global:
  resolve_timeout: 16m

templates:
  - ./*.tmpl

inhibit_rules:
# More severe alerts mute less urgent ones.
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

route:
  group_by: ['region', 'alertname', 'cluster']
  group_wait: 1m
  group_interval: 7m
  repeat_interval: 12h
  receiver: dev-null

  - receiver: slack_nannies
    continue: true
    match_re:
      context: nanny
      severity: critical|warning|info
      region: ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  # owner: Thomas Grainchen / Olaf Heydorn
  - receiver: slack_snmp
    continue: true
    match_re:
      context: snmp

  - receiver: slack_k8s
    continue: true
    match_re:
      tier: k8s
      severity: critical|warning|info
      cluster_type: controlplane|kubernikus|metal|scaleout|virtual
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
      service: arc|backup|barbican|castellum|cinder|cfm|designate|elektra|elk|glance|hermes|ironic|keystone|limes|lyra|maia|manila|neutron|nova|sentry|swift
      region: qa-de-1|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_sre
    continue: false
    match_re:
      tier: sre

  - receiver: dev-null
    continue: false
    match_re:
      cluster: k-master

  # ======= Routing for on duty service =======

  # ---- API  ----
  - receiver: pagerduty_api
    continue: true
    match_re:
      tier: os|k8s|kks
      severity: critical
      cluster_type: controlplane|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_api_critical
    continue: false
    match_re:
      tier: os|k8s|kks
      severity: critical
      cluster_type: controlplane|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_api_warning
    continue: false
    match_re:
      tier: os|k8s|kks
      severity: warning
      cluster_type: controlplane|kubernikus|metal|scaleout|virtual
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  - receiver: slack_api_info
    continue: false
    match_re:
      tier: os|k8s|kks
      severity: info
      cluster_type: metal
      region: global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|eu-de-1|eu-de-2|eu-nl-1|eu-ru-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3

  # ---- DUTY Metal ----
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

  # ---- DUTY VMware ----
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

  # ---- DUTY network ----
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

  # =======  QA / DEV & Labs =======
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

  # ======= SPECIFIC ALERT NOTIFICATION  =======

  # ---- webhook handler: metal ----
  - receiver: wham_metal
    continue: false
    match_re:
      tier: metal
      severity: critical|warning|info
      region: qa-de-1|ap-jp-1|eu-ru-1

  # Alerts that are posted to this receiver might not be properly configured.
  - receiver: dev-null
    continue: false

receivers:
- name: dev-null
  slack_configs:
    - api_url: {{ required "slack.devnullWebhook_url undefined" .Values.slack.devnullWebhookURL | quote }}
      username: "Control Plane"
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

- name: slack_metal_info
  slack_configs:
    - channel: '#alert-metal-info'
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.metal.warningWebhookURL undefined" .Values.slack.metal.warningWebhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.metal.criticalWebhookURL undefined" .Values.slack.metal.criticalWebhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      username: "Control Plane"
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
      api_url: {{ required "slack.network.criticalWebhookURL undefined" .Values.slack.network.criticalWebhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.vmware.warningWebhookURL undefined" .Values.slack.vmware.warningWebhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.vmware.criticalWebhookURL undefined" .Values.slack.vmware.criticalWebhookURL | quote }}
      username: "Control Plane"
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

# slack duty api
- name: slack_api_info
  slack_configs:
    - channel: '#alert-api-info'
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.api.warningWebhookURL undefined" .Values.slack.api.warningWebhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.api.criticalWebhookURL undefined" .Values.slack.api.criticalWebhookURL | quote }}
      username: "Control Plane"
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

- name: slack_qa
  slack_configs:
    - channel: '#alert-qa-{{"{{ .CommonLabels.severity }}"}}'
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.kubernikus.criticalWebhookURL undefined" .Values.slack.kubernikus.criticalWebhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
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
      api_url: {{ required "slack.webhookURL undefined" .Values.slack.webhookURL | quote }}
      username: "Control Plane"
      title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
      title_link: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
      text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
      pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
      icon_emoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
      color: {{`'{{template "slack.sapcc.color" . }}'`}}
      send_resolved: true

- name: pagerduty_api
  pagerduty_configs:
    - service_key: {{ required "pagerduty.api.serviceKey undefined" .Values.pagerduty.api.serviceKey | quote }}
      description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
      component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
      group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
      details:
        Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
        Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
        Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
        Fingerprint: {{"'{{template \"pagerduty.sapcc.fingerprint\" . }}'"}}
        Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
        Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
        Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
        Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
        firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}

- name: pagerduty_metal
  pagerduty_configs:
    - service_key: {{ required "pagerduty.metal.serviceKey undefined" .Values.pagerduty.metal.serviceKey | quote }}
      description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
      component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
      group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
      details:
        Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
        Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
        Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
        Fingerprint: {{"'{{template \"pagerduty.sapcc.fingerprint\" . }}'"}}
        Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
        Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
        Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
        Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
        firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}

- name: pagerduty_network
  pagerduty_configs:
    - service_key: {{ required "pagerduty.network.serviceKey undefined" .Values.pagerduty.network.serviceKey | quote }}
      description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
      component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
      group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
      details:
        Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
        Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
        Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
        Fingerprint: {{"'{{template \"pagerduty.sapcc.fingerprint\" . }}'"}}
        Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
        Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
        Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
        Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
        firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}

- name: pagerduty_vmware
  pagerduty_configs:
    - service_key: {{ required "pagerduty.vmware.serviceKey undefined" .Values.pagerduty.vmware.serviceKey | quote }}
      description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
      component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
      group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
      details:
        Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
        Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
        Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
        Fingerprint: {{"'{{template \"pagerduty.sapcc.fingerprint\" . }}'"}}
        Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
        Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
        Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
        Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
        firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}

- name: pagerduty_alertchain_test
  pagerduty_configs:
    - service_key: {{ required "pagerduty.alertTest.serviceKey undefined" .Values.pagerduty.alertTest.serviceKey | quote }}
      description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
      component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
      group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
      details:
        Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
        Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
        Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
        Fingerprint: {{"'{{template \"pagerduty.sapcc.fingerprint\" . }}'"}}
        Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
        Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
        Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
        Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
        firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}
