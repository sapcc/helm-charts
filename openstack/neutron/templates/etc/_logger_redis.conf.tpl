# Use unix socket for communication
unixsocket /var/run/redis/redis.sock

# Allow access from the PODs containers
unixsocketperm 777

# Limit connections to a single host
protected-mode yes

# Disable Persistence
appendonly no

# Limit databases to default "0"
databases 1

# Cache size
maxmemory 500mb

# Clean up by removing random key having an expire set.
maxmemory-policy volatile-random

# Run cleanup in background
active-expire-effort 1

tcp-keepalive 300
