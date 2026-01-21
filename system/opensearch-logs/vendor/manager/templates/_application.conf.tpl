# Secret will be used to sign session cookies, CSRF tokens and for other encryption utilities.
secret = "{{ randAlphaNum 32 }}"

# Application base path
basePath = "/"

# Defaults to RUNNING_PID at the root directory of the app.
# To avoid creating a PID file set this value to /dev/null
#pidfile.path = "/var/run/cerebro.pid"
pidfile.path=/dev/null

# Rest request history max size per user
rest.history.size = 50 // defaults to 50 if not specified

# Path of local database file
#data.path: "/var/lib/cerebro/cerebro.db"
data.path = "./cerebro.db"

# not sure if this is maybe needed
# The application languages
# ~~~~~
#play.i18n.langs=["en"]

# A list of known hosts
hosts = [
{{- if .Values.opensearch_manager.enabled }}
  {
    host = "https://opensearch-logs-client.opensearch-logs:9200"
    name = "{{ .Values.global.cluster }} OpenSearch Logs Cluster"
    auth = {
      username = "{{.Values.global.users.admin.username}}"
      password = "{{.Values.global.users.admin.password}}"
    }
    auth2 = {
      username = "{{.Values.global.users.admin2.username}}"
      password = "{{.Values.global.users.admin2.password}}"
    }
  },
{{- end }}
]

# Authentication
auth = {
  type: ldap
  settings: {
    url = "ldaps://{{.Values.global.ldap.host}}:{{.Values.global.ldap.port}}"
    method = "simple"
    base-dn = "{{.Values.global.ldap.search_base_dbs}},{{.Values.global.ldap.suffix}}"
    bind-dn = "{{.Values.global.ldap.bind_dn}},{{.Values.global.ldap.suffix}}"
    bind-pw = "{{.Values.global.ldap.password}}"
    user-template = "%s@{{.Values.global.ldap.userdomain}}"
    group-search {
      user-attr = "sAMAccountName"
      user-attr-template = "%s"
      group = "memberOf={{.Values.global.ldap.user_group}},{{.Values.global.ldap.group_search_base_dns}},{{.Values.global.ldap.suffix}}"
    }
  }
}
{{- if .Values.opensearch_manager.enabled }}
play.ws.ssl {
  trustManager = {
    stores = [
      { type = "PEM", path = "/opt/certs/ca.crt" }
    ]
  }
}
play.ws.ssl.loose.acceptAnyCertificate=true
{{- end }}
