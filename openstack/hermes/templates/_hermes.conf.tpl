[hermes]
PolicyFilePath = "/etc/hermes/policy.json"

[API]
ListenAddress = "0.0.0.0:80"

[elasticsearch]
url = "{{.Values.hermes_elasticsearch_protocol}}://{{.Values.hermes_elasticsearch_host}}:{{.Values.hermes_elasticsearch_port}}"

[keystone]
auth_url = "{{.Values.hermes.auth_url}}"
username = "hermes"
password = "{{.Values.hermes.password}}"
user_domain_name = "Default"
project_domain_name = "Default"
project_name = "service"
