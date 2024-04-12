[hermes]
PolicyFilePath = "/etc/hermes/policy.json"

[API]
ListenAddress = "0.0.0.0:80"

[elasticsearch]
url = "https://{{.Values.hermes_elasticsearch_host}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.hermes_elasticsearch_port}}"

[keystone]
auth_url = "{{.Values.hermes.auth_url}}"
username = "{{.Values.hermes.username | default "default"}}"
password = "{{.Values.hermes.password | default "default"}}"
user_domain_name = "Default"
project_domain_name = "Default"
project_name = "service"
