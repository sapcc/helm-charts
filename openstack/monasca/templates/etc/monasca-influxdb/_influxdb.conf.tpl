# Welcome to the InfluxDB configuration file.

# If hostname (on the OS) doesn't return a name that can be resolved by the other
# systems in the cluster, you'll have to set the hostname to an IP or something
# that can be resolved here.
# hostname = ""
bind-address = ":8088"
reporting-disabled = true
hostname = "localhost"

[authentication]
  enabled = true


[logging]
  # logging level can be one of "debug", "info", "warn" or "error"
  level  = "{{.Values.monasca_influxdb_loglevel}}"
  file   = "stdout"         # Monsoon: log to stdout for Docker
  write-tracing = false      # If true, enables detailed logging of the write system (NOT USABLE FOR PRODUCTION).
  http-access = false        # If true, logs each HTTP access to the system.
  raft-tracing = false

[meta]
  dir = "/var/opt/influxdb/meta"
  retention-autocreate = true
  logging-enabled =true
  pprof-enabled = false
  lease-duration = "1m0s"

[data]
  dir = "/var/opt/influxdb/data"
  engine = "tsm1"
  wal-dir = "/var/opt/influxdb/wal"
  wal-logging-enabled = false
  query-log-enabled = false
  cache-max-memory-size = 524288000
  cache-snapshot-memory-size = 26214400
  cache-snapshot-write-cold-duration = "1h0m0s"
  compact-full-write-cold-duration = "24h0m0s"
  max-points-per-block = 0
  data-logging-enabled = false

# permit backup (used for updates of nodes)
[snapshot]
  enabled = true # Disabled by default if not set.

[cluster]
  shard-writer-timeout = "10s"
  write-timeout = "5s"

[retention]
  enabled = true
  check-interval = "30m0s"

[admin]
  enabled = true
  port = 8083
  https_enabled = false

[http]
  enabled = true
  bind-address = ":{{.Values.monasca_influxdb_port_internal}}"
  auth-enabled = true
  log-enabled = true
  write-tracing = false
  pprof-enabled = false
  https-enabled = false
  max-row-limit = 10000

[monitoring]
  enabled = true 
  store-database = "_internal"
  store-interval = "1m"
