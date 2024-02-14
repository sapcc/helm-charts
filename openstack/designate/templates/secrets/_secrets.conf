[DEFAULT]
transport_url = rabbit://{{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/designate/rabbitmq-user/openstack/username" {{"}}"}}:{{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/designate/rabbitmq-user/openstack/password" {{"}}"}}@{{ include "rabbitmq_host" . }}:{{ .Values.rabbitmq.port }}/
