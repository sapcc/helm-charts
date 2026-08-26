server:
    interface: 0.0.0.0@53
    interface: ::@53
    root-hints: "/usr/share/dns/root.hints"
    module-config: "respip iterator"
    use-syslog: no
    do-ip4: yes
    do-ip6: yes
    do-udp: yes
    do-tcp: yes
    cache-max-negative-ttl: 30
    cache-max-ttl: 28800
    # time to live for entries in the host cache incl roundtrip timing
    infra-host-ttl: 60
    # to keep probing hosts that were marked down
    infra-keep-probing: yes
    # prefetch cache before expiration
    prefetch: yes
    # to serve stale records
    serve-expired: yes
    serve-expired-ttl: 86400
    serve-expired-client-timeout: 1800
    so-reuseport: yes
    local-zone: "10.in-addr.arpa." transparent
    local-zone: "16.172.in-addr.arpa." transparent
    local-zone: "17.172.in-addr.arpa." transparent
    local-zone: "18.172.in-addr.arpa." transparent
    local-zone: "19.172.in-addr.arpa." transparent
    local-zone: "20.172.in-addr.arpa." transparent
    local-zone: "21.172.in-addr.arpa." transparent
    local-zone: "22.172.in-addr.arpa." transparent
    local-zone: "23.172.in-addr.arpa." transparent
    local-zone: "24.172.in-addr.arpa." transparent
    local-zone: "25.172.in-addr.arpa." transparent
    local-zone: "26.172.in-addr.arpa." transparent
    local-zone: "27.172.in-addr.arpa." transparent
    local-zone: "28.172.in-addr.arpa." transparent
    local-zone: "29.172.in-addr.arpa." transparent
    local-zone: "30.172.in-addr.arpa." transparent
    local-zone: "31.172.in-addr.arpa." transparent
    local-zone: "168.192.in-addr.arpa." transparent
    local-zone: "64.100.in-addr.arpa." transparent

