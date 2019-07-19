# Secret will be used to sign session cookies, CSRF tokens and for other encryption utilities.
# It is highly recommended to change this value before running cerebro in production.
secret="{{.Values.hermes.elasticsearch.manager_secret}}"

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
  {
    host = "http://elasticsearch.hermes:9200"
    name = "hermes cluster"
  }
]

# Authentication
auth = {
  type: ldap
  settings: {
    url = "ldaps://{{.Values.ldap.host}}:{{.Values.ldap.port}}"
    base-dn = "{{.Values.ldap.search_base_dbs}},{{.Values.ldap.suffix}}"
    bind-dn = "{{.Values.ldap.bind_dn}},{{.Values.ldap.suffix}}"
    bind-pw = "{{.Values.ldap.password}}"
    user-domain = "{{.Values.ldap.userdomain}}"
    userAttr = "sAMAccountName"
    userGroup = "{{.Values.ldap.user_group}},{{.Values.ldap.suffix}}"
  }
}
