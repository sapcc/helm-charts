# Secret will be used to sign session cookies, CSRF tokens and for other encryption utilities.
# It is highly recommended to change this value before running cerebro in production.
secret="{{.Values.manager_secret}}"

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
    host = "http://{{.Values.global.endpoint_host_internal}}:{{.Values.global.http_port}}"
    name = "elk cluster"
    auth = {
      username = "{{.Values.global.admin_user}}"
      password = "{{.Values.global.admin_password}}"
    }
  }
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
      group = "{{.Values.global.ldap.user_group}},{{.Values.global.ldap.suffix}}"
    }
  }
}
