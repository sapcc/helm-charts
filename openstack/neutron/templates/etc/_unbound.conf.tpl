server:
    interface: 0.0.0.0@53
    interface: ::@53
    root-hints: "/usr/share/dns/root.hints"
    module-config: "respip iterator"
    use-syslog: no

    so-reuseport: yes
    access-control: 0.0.0.0/0 allow

    do-ip4: yes
    do-ip6: yes
    do-udp: yes
    do-tcp: yes

    # use more than one thread
    num-threads: 4

    # Number of TCP buffers to allocate per thread, default 10.
    # "For larger installations increasing this value is a good idea."
    outgoing-num-tcp: 500
    incoming-num-tcp: 500

    # keep UDP ports around a bit, so late upstream responses 
    # do not hit a closed port
    delay-close: 2000

    # limit negative caching, so we pick up new entries faster
    cache-max-negative-ttl: 60

    # do not cache entries longer than 4 hours.
    # note that we are using prefetching and serve expired records
    cache-max-ttl: 14400

    # prefetch cache entries that are about to expire
    prefetch: yes

    # if a cache TTL is expired and we get a query for it,
    # first try for 1800ms to resolve
    serve-expired-client-timeout: 1800
    # if this fails serve stale records from cache
    serve-expired: yes
    # but only for one hour.
    serve-expired-ttl: 3600

