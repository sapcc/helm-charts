
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

    # use more than one thread - watch memory footprint!
    num-threads: 1

    # these are numbers per thread
    # we are running many unbounds in a pod, so we have to reduce
    # the memory footprint a lot here:

    rrset-cache-slabs: 1
    rrset-cache-size: 1m

    msg-cache-slabs: 1
    msg-cache-size: 1m

    key-cache-slabs: 1
    key-cache-size: 1m

    neg-cache-size: 1m

    infra-cache-slabs: 1
    infra-cache-numhosts: 5

    # only relevant when no forwarders are set
    target-fetch-policy: "2 1 0 0 0 0"

    # harden-large-queries: "yes"
    # harden-short-bufsize: "yes"

    # we have libevent, so can increase that according to docs
    outgoing-range: 8192
    num-queries-per-thread: 4096

    # Number of ... TCP buffers to allocate per thread.
    # "For larger installations increasing this value is a good idea."
    # adds to memory footprint.
    outgoing-num-tcp: 50  # this limits TCP service, but uses less buffers.
    incoming-num-tcp: 100

    # outgoing-range: 60  # uses less memory, but less performance.

    # keep UDP ports around a bit, so
    # late upstream responses do not hit a closed port
    delay-close: 2000

    # limit negative caching, so we pick up new entries faster,
    # but try avoiding hammering upstreams
    cache-max-negative-ttl: 20

    # do not cache entries longer than 4 hours locally
    cache-max-ttl: 14400


    # prefetch cache entries that are about to expire
    # when queried by a client
    prefetch: yes

    # https://unbound.docs.nlnetlabs.nl/en/latest/topics/core/serve-stale.html

    # if a cache TTL is expired and we get a client query for it,
    # try to resolve for timeout msecs, before returning expired data.
    # default is 1800
    serve-expired-client-timeout: 2400
    # discard-timeout needs to be larger than serve-expired-client-timeout
    discard-timeout: 2500

    # if this fails serve stale records from cache
    serve-expired: yes
    # but only for half an hour. Default is 24h, but
    # we do not want to hide errors and risk a nightly incident hours
    # after an issue somewhere upstream
    serve-expired-ttl: 1800

    statistics-interval: 0
    extended-statistics: yes
    # for prometheus:
    statistics-cumulative: yes

