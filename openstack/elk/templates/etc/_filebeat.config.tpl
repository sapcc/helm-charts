filebeat.config:
  inputs:
    # Mounted `filebeat-inputs` configmap:
    path: ${path.config}/inputs.d/*.yml
    # Reload inputs configs as they change:
    reload.enabled: false
  modules:
    path: ${path.config}/modules.d/*.yml
    # Reload module configs as they change:
    reload.enabled: false

# To enable hints based autodiscover, remove `filebeat.config.inputs` configuration and uncomment this:
#filebeat.autodiscover:
#  providers:
#    - type: kubernetes
#      hints.enabled: true

processors:
  - add_cloud_metadata:

#cloud.id: ${ELASTIC_CLOUD_ID}
#cloud.auth: ${ELASTIC_CLOUD_AUTH}

output.elasticsearch:
  hosts: ['{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}']
  username: {{.Values.elk_elasticsearch_data_user}}
  password: {{.Values.elk_elasticsearch_data_password}}
