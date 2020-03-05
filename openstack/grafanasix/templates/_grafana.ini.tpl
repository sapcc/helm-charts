##################### Grafana Configuration Example #####################
#
# Everything has defaults so you only need to uncomment things you want to
# change

# possible values : production, development
; app_mode = production

# instance name, defaults to HOSTNAME environment variable value or hostname if HOSTNAME var is empty
; instance_name = ${HOSTNAME}

#################################### Paths ####################################
[paths]
# Path to where grafana can store temp files, sessions, and the sqlite3 db (if that is used)
#
data = /var/lib/grafana
#
# Directory where grafana can store logs
#
;logs = /var/log/grafana
#
# Directory where grafana will automatically scan and look for plugins
#
plugins = /var/lib/grafana/plugins

#
#################################### Server ####################################
[server]
# Protocol (http, https, socket)
;protocol = http

# The ip address to bind to, empty will bind to all interfaces
;http_addr =

# The http port  to use
;http_port = 3000

# The public facing domain name used to access grafana from a browser
;domain = localhost

# Redirect to correct domain if host header does not match domain
# Prevents DNS rebinding attacks
;enforce_domain = false

# The full public facing url you use in browser, used for redirects and emails
# If you use reverse proxy and sub path specify full url (with sub path)
;root_url = http://localhost:3000

# Log web requests
;router_logging = false

# the path relative working path
;static_root_path = public

# enable gzip
;enable_gzip = false

# https certs & key file
;cert_file =
;cert_key =

# Unix socket path
;socket =

#################################### Database ####################################
[database]
type={{.Values.grafana.db.type}}
host={{.Release.Name}}-pgsql.{{.Release.Namespace}}
user={{.Values.postgresql.postgresUser}}
password={{.Values.postgresql.postgresPassword}}

ssl_mode=disable
#type=sqlite3
#path=/etc/grafana/grafana.db

#################################### Session ####################################
[session]
# Either "memory", "file", "redis", "mysql", "postgres", default is "file"
provider = postgres
#provider = file

# Provider config options
# memory: not have any config yet
# file: session dir path, is relative to grafana data_path
# redis: config like redis server e.g. `addr=127.0.0.1:6379,pool_size=100,db=grafana`
# mysql: go-sql-driver/mysql dsn config string, e.g. `user:password@tcp(127.0.0.1:3306)/database_name`
#;provider_config = sessions
provider_config = user={{.Values.postgresql.postgresUser}} password={{.Values.postgresql.postgresPassword}} host={{.Release.Name}}-pgsql.{{.Release.Namespace}} port=5432 dbname=grafana sslmode=disable
#provider_config = .

# Session cookie name
;cookie_name = grafana_sess

# If you use session in https only, default is false
;cookie_secure = false

# Configure 7-day session length to match cookie lifetime
session_life_time = 604800


#################################### Security ####################################
[security]
# default admin user, created on startup
admin_user = {{.Values.grafana.admin.user}}

# default admin password, can be changed before first start of grafana,  or in profile settings
admin_password = {{.Values.grafana.admin.password}}

# used for signing
;secret_key = SW2YcwTIb9zpOOhoPsMm

# Auto-login remember days
;login_remember_days = 7
;cookie_username = grafana_user
;cookie_remember_name = grafana_remember

# disable gravatar profile images
;disable_gravatar = false

# data source proxy whitelist (ip_or_domain:port separated by spaces)
;data_source_proxy_whitelist =

# allow embedding of grafana in a frame etc. - required for the kiosk mode
allow_embedding = true

[snapshots]
# snapshot sharing options
;external_enabled = true
;external_snapshot_url = https://snapshots-origin.raintank.io
;external_snapshot_name = Publish to snapshot.raintank.io

# remove expired snapshot
;snapshot_remove_expired = true

# remove snapshots after 90 days
;snapshot_TTL_days = 90

#################################### Users ####################################
# disable user signup / registration
allow_sign_up = false

# Do not allow non admin users to create organizations
allow_org_create = false

# Set to true to automatically assign new users to the default organization (id 1)
auto_assign_org = false

# Default role new users will be automatically assigned (if auto_assign_org above is set to true)
#auto_assign_org_role = Viewer

# Require email validation before sign up completes
verify_email_enabled = false

# Background text for the user field on the login page
login_hint = UserID[@domain]

{{- if .Values.grafana.auth.tls_client_auth.enabled}}
[auth.proxy]
enabled = true
header_name = X-REMOTE-USER
header_property = username
auto_sign_up = false
{{- end }}

[auth.basic]
enabled = {{ default true .Values.grafana.auth.basic_auth.enabled }}


#################################### Auth LDAP ##########################
{{- if .Values.grafana.auth.ldap.enabled}}
[auth.ldap]
enabled = true
config_file = /grafana-etc/ldap.toml
allow_sign_up = true
{{- end }}


#################################### Anonymous Auth ##########################
{{- if .Values.grafana.auth.anonymous.enabled}}
[auth.anonymous]
# enable anonymous access
enabled = true

# specify organization name that should be used for unauthenticated users
org_name = "Main Org."

# Role for unauthenticated users, other valid values are `Editor` and `Admin`
org_role = Viewer
{{- end }}


#################################### Logging ##########################
[log]
level = {{.Values.grafana.log_level}}
mode = console
#filters = ldap:debug

[log.console]
level = {{.Values.grafana.log_level}}

# log line format, valid options are text, console and json
format = json

;#################################### Dashboard JSON files ##########################
#[dashboards.json]
#enabled = true
#path = /dashboards/

#################################### Alerting ############################
[alerting]
# Disable alerting engine & UI features
;enabled = true
enabled = false
# Makes it possible to turn off alert rule execution but alerting UI is visible
;execute_alerts = true
execute_alerts = false
