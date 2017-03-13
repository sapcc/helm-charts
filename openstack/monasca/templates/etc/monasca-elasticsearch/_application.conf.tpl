# Secret will be used to sign session cookies, CSRF tokens and for other encryption utilities.
# It is highly recommended to change this value before running cerebro in production.
secret = "{{.Values.monasca_elasticsearch_manager_secret}}"

# Application base path
basePath = "/"

# Defaults to RUNNING_PID at the root directory of the app.
# To avoid creating a PID file set this value to /dev/null
#pidfile.path = "/var/run/cerebro.pid"

# Rest request history max size per user
rest.history.size = 50 // defaults to 50 if not specified

# Path of local database file
data.path = "./cerebro.db"

# Authentication
auth = {
  type: basic
    settings: {
      username = "{{.Values.monasca_elasticsearch_admin_user}}"
      password = "{{.Values.monasca_elasticsearch_password_user}}"
    }
}

# A list of known hosts
hosts = [
  {
    host = "http://{{.Values.monasca_elasticsearch_endpoint_host_internal}}:{{.Values.monasca_elasticsearch_port_internal}}"
    name = "Secured Cluster"
    auth = {
      username = "{{.Values.monasca_elasticsearch_admin_user}}"
      password = "{{.Values.monasca_elasticsearch_password_user}}"
    }
  }
]
