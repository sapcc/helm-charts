[DEFAULT]

log_config_append = /etc/config/logging.conf
# logging_context_format_string = %(process)d %(levelname)s %(name)s [%(request_id)s g%(global_request_id)s %(user_identity)s] %(instance)s%(message)s
# logging_default_format_string = %(process)d %(levelname)s %(name)s [-] %(instance)s%(message)s
# logging_exception_prefix = %(process)d ERROR %(name)s %(instance)s
# logging_user_identity_format = usr %(user)s prj %(tenant)s dom %(domain)s usr-dom %(user_domain)s prj-dom %(project_domain)s

[bastion]
max_inactive_days={{.Values.bastion.max_inactive_days}}


[prometheus]
global_url= {{.Values.prometheus.url}}
sso_cert="/etc/secret/prom_cert.pem"
sso_key="/etc/secret/prom_cert.key"

api_path="/api/v1/query"
range="[30d:15m]"
