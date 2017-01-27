export OS_REGION_NAME={{.Values.cluster_region}}
export OS_USER_DOMAIN_NAME={{.Values.monasca_health_user_domain_name}}
export OS_PROJECT_NAME={{.Values.monasca_health_project_name}}
export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL={{.Values.keystone_api_endpoint_protocol_public}}://{{.Values.keystone_api_endpoint_host_public}}:{{.Values.keystone_api_port_public}}/v3
export OS_USERNAME={{.Values.monasca_health_user_name}}
export OS_PASSWORD={{.Values.monasca_health_user_password}}
# needed for the official monasca cli
export OS_DOMAIN_NAME={{.Values.monasca_health_project_domain_name}}
# needed for our monasca cli
export OS_PROJECT_DOMAIN_NAME={{.Values.monasca_health_project_domain_name}}
export OS_CACERT=/etc/ssl/certs/ca-certificates.crt
# explicitely specify the monasca-api url, so that we test the public url including the ingress
export MONASCA_API_URL={{.Values.monasca_api_endpoint_protocol_public}}://{{.Values.monasca_api_endpoint_host_public}}:{{.Values.monasca_api_port_public}}/v2.0
# how many non alarm triggering metrics to send
export NON_ALARM_LOOPS={{.Values.monasca_health_non_alarm_loops}}
# how many seconds to wait between all of them
export NON_ALARM_WAIT={{.Values.monasca_health_non_alarm_wait}}
# how many alarm triggering metrics to send
export ALARM_LOOPS={{.Values.monasca_health_alarm_loops}}
# how many seconds to wait between all of them
export ALARM_WAIT={{.Values.monasca_health_alarm_wait}}
# after how many minutes to alert again if monasca is still down
export REALERT_INTERVAL={{.Values.monasca_health_realert_interval}}
# hostname where monasca can reach the webhook listener
export WEBHOOK_HOSTNAME={{.Values.monasca_health_webhook_hostname}}
# port of the webhook listener
export LISTEN_PORT={{.Values.monasca_health_listen_port}}
# slack channel to send the alerts to
export SLACK_CHANNEL={{.Values.monasca_health_slack_channel}}
# slack incoming webhook to use for sending stuff to slack
export SLACK_INCOMING_WEBHOOK={{.Values.monasca_health_slack_incoming_webhook}}
