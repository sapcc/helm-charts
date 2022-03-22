[loggers]
keys = root, bastion, warnings, ldap, ldappool, amqp, amqplib, oslo_messaging, oslo_policy, oslo_service, sqlalchemy

[handlers]
keys = file,stderr, stdout, null

[formatters]
keys = context, default

[logger_root]
level = ERROR
handlers = file,stdout,stderr,null

[logger_bastion]
level = DEBUG
handlers = file,stdout
qualname = bastion


[logger_oslo_messaging]
level = ERROR
handlers = file,stdout,stderr,null
qualname = oslo.messaging

[logger_oslo_policy]
level = WARNING
handlers = file,stdout
qualname = oslo_policy

[logger_oslo_service]
level = INFO
handlers = file,stdout
qualname = oslo_service

[logger_ldap]
level = ERROR
handlers = file,stdout
qualname = keystone.common.ldap.core

[logger_ldappool]
level = ERROR
handlers = file,stdout
qualname = ldappool

[logger_amqp]
level = ERROR
handlers = file,stdout
qualname = amqp

[logger_amqplib]
level = ERROR
handlers = file,stdout
qualname = amqplib

[logger_sqlalchemy]
level = WARNING
handlers = file,stdout
qualname = sqlalchemy
# "level = DEBUG" logs SQL queries.
# "level = DEBUG" logs SQL queries and results.
# "level = WARNING" logs neither.  (Recommended for production systems.)

[logger_warnings]
level = WARNING
handlers = file,stdout
qualname = py.warnings

[handler_file]
class=handlers.WatchedFileHandler
level=DEBUG
formatter=context
args=('/var/log/bastion.log',)


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


[formatter_context]
class = oslo_log.formatters.ContextFormatter

[formatter_default]
format = %(message)s