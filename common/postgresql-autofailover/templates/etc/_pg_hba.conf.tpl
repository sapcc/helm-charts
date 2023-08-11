# TYPE  DATABASE                          USER                          ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all                               all                                                   trust

# IPv4 local connections:
host    all                               all                           127.0.0.1/32            trust

# IPv6 local connections:
host    all                               all                           ::1/128                 trust

# pg_auto_failover monitor
host    pg_auto_failover                  autoctl_node                  0.0.0.0/0               trust

# pg_auto_failover node
host    {{.Values.postgresDatabase}}      {{.Values.postgresUser}}      0.0.0.0/0               trust
host    {{.Values.postgresDatabase}}      pgautofailover_replicator     0.0.0.0/0               trust
host    replication                       pgautofailover_replicator     0.0.0.0/0               trust
host    postgres                          pgautofailover_replicator     0.0.0.0/0               trust
host    all                               pgautofailover_monitor        0.0.0.0/0               trust
