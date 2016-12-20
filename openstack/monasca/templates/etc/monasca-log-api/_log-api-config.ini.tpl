{{- define "monasca_log_api_log_api_config_ini_tpl" -}}
[DEFAULT]
name = monasca_log_api

[pipeline:main]
pipeline = statsd auth roles sentry api

[app:api]
paste.app_factory = monasca_log_api.server:launch

[filter:auth]
paste.filter_factory = monasca_log_api.healthcheck.keystone_protocol:filter_factory

[filter:roles]
paste.filter_factory = monasca_log_api.middleware.role_middleware:RoleMiddleware.factory

[filter:statsd]
use = egg:ops-middleware#statsd
statsd_host=localhost
statsd_port=8125
statsd_prefix=monasca.log

[filter:sentry]
use = egg:ops-middleware#sentry
dsn = {{.Values.monasca_sentry_dsn}}
level = ERROR

[server:main]
use = egg:gunicorn#main
host = 0.0.0.0
port = {{.Values.monasca_log_api_port_internal}}
workers = 4
proc_name = monasca_log_api
{{ end }}
