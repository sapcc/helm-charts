# Reference for configuration file syntax: <https://quay.github.io/clair/reference/config.html>
# Reference for DB connection strings: <https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING>
#
# This file is `/etc/clair/config.yaml.in`, not the actual config file. During startup, a script
# replaces the password placeholders with the actual passwords from the environment vars. Upstream
# does not support reading passwords from env vars directly, cf. <https://github.com/quay/clair/issues/346>.

http_listen_addr: "0.0.0.0:8080" # exposes API endpoints
introspection_addr: "0.0.0.0:8081" # exposes metrics/health endpoints
log_level: {{ quote .Values.clair.log_level }}

indexer:
  connstring: "host=clair-postgresql port=5432 dbname=clair user=postgres password=%POSTGRES_PASSWORD% sslmode=disable application_name=c-indexer"
  scanlock_retry: 10
  layer_scan_concurrency: 5
  migrations: true
  scanner: {} # no special config options for scanners yet

matcher:
  connstring: "host=clair-postgresql port=5432 dbname=clair user=postgres password=%POSTGRES_PASSWORD% sslmode=disable application_name=c-matcher"
  max_conn_pool: 32
  indexer_addr: "" # ignored since we're running in combo mode
  migrations: true

updaters:
  sets: [ alpine, rhel, suse, ubuntu ]
  config: {} # no special config options for updaters yet

notifier:
  connstring: "host=clair-postgresql port=5432 dbname=clair user=postgres password=%POSTGRES_PASSWORD% sslmode=disable application_name=c-notifier"
  migrations: true
  indexer_addr: "" # ignored since we're running in combo mode
  matcher_addr: "" # ignored since we're running in combo mode
  poll_interval: 1000h # basically never, we don't use the notifier
  delivery_interval: 1000h # basically never, we don't use the notifier
  disable_summary: false
  webhook: null
  amqp: null
  stomp: null

auth:
  psk:
    key: [ "%AUTH_PRESHARED_KEY%" ]
    issuer: [ keppel-api@{{.Values.global.region}}.cloud.sap ]

metrics:
  name: prometheus
