machine ironic-rabbitmq
login {{ .Values.rabbitmq.metrics.user | include "resolve_secret" }}
password {{ .Values.rabbitmq.metrics.password | include "resolve_secret" }}