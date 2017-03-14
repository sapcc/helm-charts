# Secret will be used to sign session cookies, CSRF tokens and for other encryption utilities.
# It is highly recommended to change this value before running cerebro in production.
play.crypto.secret="{{.Values.monasca_elasticsearch_manager_secret}}"


# The application languages
# ~~~~~
play.i18n.langs=["en"]

play.modules.enabled += "controllers.auth.Module"
play.modules.enabled += "elastic.ElasticModule"

# A list of known hosts
hosts = [
  {
    host = "http://{{.Values.monasca_elasticsearch_endpoint_host_internal}}:{{.Values.monasca_elasticsearch_port_internal}}"
    name = "Secured Cluster"
    auth = {
      username = "{{.Values.monasca_elasticsearch_admin_user}}"
      password = "{{.Values.monasca_elasticsearch_admin_password}}"
    }
  }
]

# Authentication
auth = {
  type: basic
    settings: {
      username = "{{.Values.monasca_elasticsearch_admin_user}}"
      password = "{{.Values.monasca_elasticsearch_admin_password}}"
    }
}

rest.history.size: 50 // defaults to 50 if not specified
data.path: "./cerebro.db"

slick.dbs.default.driver="slick.driver.SQLiteDriver$"
slick.dbs.default.db.driver=org.sqlite.JDBC
slick.dbs.default.db.url="jdbc:sqlite:"${data.path}
play.evolutions.db.default.autoApply = true
