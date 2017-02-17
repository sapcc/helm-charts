[DEFAULT]
name = monasca_api

[pipeline:main]
# Add validator in the pipeline so the metrics messages can be validated.
pipeline = statsd request_id auth sentry api

[app:api]
paste.app_factory = monasca_api.api.server:launch

[filter:auth]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:request_id]
paste.filter_factory = oslo_middleware.request_id:RequestId.factory

[filter:statsd]
use = egg:ops-middleware#statsd
statsd_host=localhost
statsd_port=8125
statsd_prefix=monasca.api

[filter:sentry]
use = egg:ops-middleware#sentry
dsn = {{.Values.monasca_sentry_dsn}}
level = ERROR

[server:main]
use = egg:gunicorn#main
host = 0.0.0.0
port = {{.Values.monasca_api_port_internal}}
workers = 4
proc_name = monasca_api

[logger_sqlalchemy]
level = INFO
handlers =
qualname = sqlalchemy.engine
