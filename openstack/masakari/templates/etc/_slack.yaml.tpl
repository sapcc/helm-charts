openstack:
  credential:
    username: masakari
    password: {{ .Values.global.masakari_service_password }}
    domain_name: default
    project_domain_name: default
    project_name: service
    auth_url: {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}
  notification:
    oldest: 600
    match: |
      [[ ne .Notification.Status "ignored" "new" ]]
    sync: true
slack:
  token: {{"{{"}} resolve "vault+kvv2:///secrets/global/masakari/slack/token" {{"}}"}}
  message:
    thread:
      channel: "#masakari"
      text: |
        HA Event `[[ .Notification.Notification_uuid ]]`
        Type: `[[ .Notification.Type ]]`
        Segment: `[[ .Segment.Name ]]`
        Host: `[[ .Host.Name ]]`
      icon_emoji: ":failed:"
    reply:
      broadcast: |
        [[ eq .Notification.Status "failed" ]]
      text: |
        Workflow: `[[ .Workflow.Name ]]` 
        State: `[[ .Workflow.State ]]`
        Progress: `[[ .Progress.Message ]]`

        [[ if eq .Notification.Status "failed" ]]:alert: Failover failed :alert:[[ end ]]
log:
  level: Debug
file: /volume/state.json 
