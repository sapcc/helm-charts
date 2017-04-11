[loggers]
keys = root, keystone, ldap

[handlers]
keys = stderr, stdout, null{{ if .Values.sentry.enabled }}, sentry{{ end }}

[formatters]
keys = context, default

[logger_root]
level = WARNING
handlers = null

[logger_keystone]
{{ if .Values.debug }}
level = DEBUG
{{ else }}
level = INFO
{{ end }}
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
qualname = keystone

[logger_ldap]
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
qualname = keystone.common.ldap.core

[logger_amqp]
level = WARNING
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
qualname = amqp

[logger_amqplib]
level = WARNING
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
qualname = amqplib

[logger_sqlalchemy]
level = WARNING
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
qualname = sqlalchemy
# "level = INFO" logs SQL queries.
# "level = DEBUG" logs SQL queries and results.
# "level = WARNING" logs neither.  (Recommended for production systems.)

[logger_eventletwsgi]
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
qualname = eventlet.wsgi.server

[handler_stderr]
class = StreamHandler
args = (sys.stderr,)
formatter = context

[handler_stdout]
class = StreamHandler
args = (sys.stdout,)
formatter = context

[handler_null]
class = logging.NullHandler
formatter = default
args = ()

{{- if .Values.sentry.enabled }}
[handler_sentry]
class=raven.handlers.logging.SentryHandler
level=ERROR
args=()
{{- end }}

[formatter_context]
class = oslo_log.formatters.ContextFormatter

[formatter_default]
format = %(message)s

