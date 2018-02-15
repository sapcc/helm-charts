[loggers]
{{- if .Values.debug }}
keys = root
{{- else }}
keys = root, keystone, cc, radius, keystonemiddleware, keystoneauth, ldap, amqp, amqplib, oslo_messaging {{ if .Values.sentry.enabled }}, raven{{ end }}
{{- end }}

[handlers]
keys = stderr, stdout, null{{ if .Values.sentry.enabled }}, sentry{{ end }}

[formatters]
keys = context, default

[logger_root]
{{- if .Values.debug }}
level = DEBUG
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{ else }}
level = ERROR
handlers = null
{{- end }}

[logger_keystone]
{{- if .Values.debug }}
level = DEBUG
handlers = null
{{- else }}
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{- end }}
qualname = keystone

[logger_cc]
{{- if .Values.debug }}
level = DEBUG
handlers = null
{{- else }}
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{- end }}
qualname = cc

[logger_radius]
{{- if .Values.debug }}
level = DEBUG
handlers = null
{{- else }}
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{- end }}
qualname = radius

[logger_keystonemiddleware]
{{- if .Values.debug }}
level = DEBUG
handlers = null
{{- else }}
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{- end }}
qualname = keystonemiddleware

[logger_keystoneauth]
{{- if .Values.debug }}
level = DEBUG
handlers = null
{{- else }}
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{- end }}
qualname = keystoneauth1

[logger_oslo_messaging]
{{- if .Values.debug }}
level = DEBUG
handlers = null
{{- else }}
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{- end }}
qualname = oslo.messaging

[logger_ldap]
{{- if .Values.debug }}
level = INFO
handlers = null
{{- else }}
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{- end }}
qualname = keystone.common.ldap.core

[logger_amqp]
{{- if .Values.debug }}
level = DEBUG
handlers = null
{{- else }}
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{- end }}
qualname = amqp

[logger_amqplib]
{{- if .Values.debug }}
level = DEBUG
handlers = null
{{- else }}
level = INFO
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{- end }}
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
{{- if .Values.debug }}
handlers = null
{{- else }}
handlers = stdout{{ if .Values.sentry.enabled }}, sentry{{ end }}
{{- end }}
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

{{ if .Values.sentry.enabled }}
[logger_raven]
level = ERROR
{{- if .Values.debug }}
handlers = null
{{- else }}
handlers = stdout
{{- end }}
qualname = raven

[handler_sentry]
class=raven.handlers.logging.SentryHandler
level=ERROR
args=()
{{ end }}

[formatter_context]
class = oslo_log.formatters.ContextFormatter

[formatter_default]
format = %(message)s

