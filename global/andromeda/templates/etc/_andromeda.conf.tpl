[DEFAULT]
# api_base_uri = http://localhost:8000
transport_url = nats://andromeda-nats:4222

[database]
connection = cockroachdb://root@andromeda-cockroachdb:26257/andromeda?sslmode=disable

[api_settings]
auth_strategy = none
policy_engine = noop
disable_pagination = false
disable_sorting = false
disable_cors = false
pagination_max_limit = 100
rate_limit = 10
