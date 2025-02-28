machine ironic-rabbitmq
login {{ .Values.rabbitmq.metrics.user }}
password "{{ .Values.rabbitmq.metrics.password }}"