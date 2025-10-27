{{- if .Values.maia.enabled }}
[maia]
prometheus_url = "http://prometheus-{{- .Values.prometheus_server.name }}-thanos-query:9090{{- .Values.prometheus_server.thanos.querier.webRouteprefix }}"
federate_url = "http://prometheus-maia-oprom:9090"
bind_address = "0.0.0.0:{{.Values.maia.listen_port}}"
# do not list label values from series older than label_value_ttl
label_value_ttl = "{{ .Values.maia.label_value_ttl }}"
[keystone]
auth_url = "{{ required "global.os_auth_url variable missing" .Values.global.os_auth_url }}"
# credentials for the Maia service user go here:
username = "{{ .Values.maia.service_user.name}}"
password = "{{ required "maia.service_user.password variable missing" .Values.maia.service_user.password }}"
user_domain_name = "{{ .Values.maia.service_user.user_domain_name }}"
project_name = "{{ .Values.maia.service_user.project_name }}"
project_domain_name = "{{ .Values.maia.service_user.project_domain_name }}"
# Once successfully verified, Maia will not recheck tokens online for this duration
token_cache_time = "{{ .Values.maia.token_cache_time }}"
policy_file = "/etc/maia/policy.json"
roles = "monitoring_admin,monitoring_viewer"
# if no user domain was specified with the username (using `@`), Maia will assume this one
default_user_domain_name = "{{ .Values.maia.default_domain }}"

{{- if .Values.maia.global_keystone.enabled }}
# Configuration for global Keystone service
[keystone.global]
auth_url = "{{ required "maia.global_keystone.auth_url variable missing" .Values.maia.global_keystone.auth_url }}"
username = "{{ .Values.maia.global_keystone.username | default .Values.maia.service_user.name }}"
password = "{{ .Values.maia.global_keystone.password | default .Values.maia.service_user.password }}"
user_domain_name = "{{ .Values.maia.global_keystone.user_domain_name | default .Values.maia.service_user.user_domain_name }}"
project_name = "{{ .Values.maia.global_keystone.project_name | default .Values.maia.service_user.project_name }}"
project_domain_name = "{{ .Values.maia.global_keystone.project_domain_name | default .Values.maia.service_user.project_domain_name }}"
{{- end }}

{{- end }}
