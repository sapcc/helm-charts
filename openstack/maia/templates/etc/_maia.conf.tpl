{{- if .Values.maia.enabled }}
[maia]
prometheus_url = "http://prometheus-maia-oprom-thanos-query:9090"
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
# any project role will be sufficient to access maia metrics
roles = ".*"
# if no user domain was specified with the username (using `@`), Maia will assume this one
default_user_domain_name = "{{ .Values.maia.default_domain }}"
{{- end }}
