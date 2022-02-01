# Kibana is served by a back end server. This controls which port to use.
server.port: 5601

# The host to bind the server to.
server.host: "0.0.0.0"

# The maximum payload size in bytes on incoming server requests.
# server.maxPayloadBytes: 1048576

# The Elasticsearch instance to use for all your queries.
elasticsearch.hosts: http://{{.Values.endpoint_host_internal}}:{{.Values.http_port}}

# preserve_elasticsearch_host true will send the hostname specified in `elasticsearch`. If you set it to false,
# then the host you use to connect to *this* Kibana instance will be sent.
# elasticsearch.preserveHost: true

# Kibana uses an index in Elasticsearch to store saved searches, visualizations
# and dashboards. It will create a new index if it doesn't already exist.
# kibana.index: ".kibana-6"

# The default application to load.
kibana.defaultAppId: "discover"

# If your Elasticsearch is protected with basic auth, these are the user credentials
# used by the Kibana server to perform maintenance on the kibana_index at startup. Your Kibana
# users will still need to authenticate with Elasticsearch (which is proxied through
# the Kibana server)
elasticsearch.username: "{{.Values.global.elk_elasticsearch_admin_user}}"
elasticsearch.password: "{{.Values.global.elk_elasticsearch_admin_password}}"

# SSL for outgoing requests from the Kibana Server to the browser (PEM formatted)
# server.ssl.cert: /path/to/your/server.crt
# server.ssl.key: /path/to/your/server.key

# Optional setting to validate that your Elasticsearch backend uses the same key files (PEM formatted)
# elasticsearch.ssl.cert: /path/to/your/client.crt
# elasticsearch.ssl.key: /path/to/your/client.key

# If you need to provide a CA certificate for your Elasticsearch instance, put
# the path of the pem file here.
# elasticsearch.ssl.ca: /path/to/your/CA.pem

# Set to false to have a complete disregard for the validity of the SSL
# certificate.
# elasticsearch.ssl.verify: true

# Time in milliseconds to wait for elasticsearch to respond to pings, defaults to
# request_timeout setting
elasticsearch.pingTimeout: 10000

# Time in milliseconds to wait for responses from the back end or elasticsearch.
# This must be > 0
elasticsearch.requestTimeout: 60000

# Time in milliseconds for Elasticsearch to wait for responses from shards.
# Set to 0 to disable.
# elasticsearch.shardTimeout: 0

# Time in milliseconds to wait for Elasticsearch at Kibana startup before retrying
# elasticsearch.startupTimeout: 5000

# Set the path to where you would like the process id file to be created.
# pid.file: /var/run/kibana.pid

# If you would like to send the log output to a file you can set the path below.
logging.dest: stdout

# Set this to true to suppress all logging output.
# logging.silent: false

# Set this to true to suppress all logging output except for error messages.
logging.quiet: true

# Set this to true to log all events, including system usage information and all requests.
#logging.verbose: true

# whitelist the headers we want to transfer from the ingress to elasticsearch
elasticsearch.requestHeadersWhitelist: [ "Authorization", "X-Remote-User" ]

xpack.monitoring.enabled: false
xpack.xpack_main.telemetry.enabled: false
xpack.monitoring.kibana.collection.enabled: false
xpack.monitoring.ui.enabled: false

map.includeElasticMapsService: false
