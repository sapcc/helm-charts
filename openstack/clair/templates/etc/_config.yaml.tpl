{{- define "clair_config" -}}
{{- $type       := index . 0 -}}
{{- $context    := index . 1 -}}

# Reference for configuration file syntax: <https://quay.github.io/clair/reference/config.html>
# Reference for DB connection strings: <https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING>
#
# This file is `/etc/clair/config.yaml.in`, not the actual config file. During startup, a script
# replaces the password placeholders with the actual passwords from the environment vars. Upstream
# does not support reading passwords from env vars directly, cf. <https://github.com/quay/clair/issues/346>.

http_listen_addr: "0.0.0.0:8080" # exposes API endpoints
introspection_addr: "0.0.0.0:8081" # exposes metrics/health endpoints
log_level: {{ quote $context.Values.clair.log_level }}

indexer:
  connstring: "host=clair-postgresql port=5432 dbname=clair user=postgres password=%POSTGRES_PASSWORD% sslmode=disable application_name=c-indexer"
  scanlock_retry: 10
  layer_scan_concurrency: 5
  migrations: true
  scanner: {} # no special config options for scanners yet

matcher:
  connstring: "host=clair-postgresql port=5432 dbname=clair user=postgres password=%POSTGRES_PASSWORD% sslmode=disable application_name=c-matcher"
  max_conn_pool: 32
  indexer_addr: "http://clair-indexer:8080"
  migrations: true
  period: {{ quote $context.Values.clair.update_interval }}

{{- if ne $type "updater" }}
  # run in its own pod to reduce database load
  disable_updaters: true
{{- end }}

  # set update_retention to a non-default value because the default value of 10
  # does not get applied correctly, causing garbage collection to not run
  # <https://github.com/quay/clair/issues/1337#issuecomment-898485216>
  update_retention: 5

matchers:
  # do NOT enable the crda matcher; it tries to make API calls that fail with 403 errors left and right
  names: [ alpine, debian, rhel, suse, ubuntu ]

updaters:
  sets: [ alpine, debian, rhel, suse, ubuntu ]
  config: {} # no special config options for updaters yet

# notifier:
#   connstring: "host=clair-postgresql port=5432 dbname=clair user=postgres password=%POSTGRES_PASSWORD% sslmode=disable application_name=c-notifier"
#   migrations: true
#   indexer_addr: "" # ignored since we're running in combo mode
#   matcher_addr: "" # ignored since we're running in combo mode
#   poll_interval: 1000h # basically never, we don't use the notifier
#   delivery_interval: 1000h # basically never, we don't use the notifier
#   disable_summary: false
#   webhook: null
#   amqp: null
#   stomp: null

auth:
  psk:
    key: "%AUTH_PRESHARED_KEY%"
    iss: [ keppel ]

metrics:
  name: prometheus
{{- end -}}
