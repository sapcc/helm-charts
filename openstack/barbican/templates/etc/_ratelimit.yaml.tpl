# List of whitelisted scopes keys (domainName/projectName).
whitelist:
  - default/service

# Override default ratelimit response.
ratelimit_response:
  status: 498 Rate Limited
  status_code: 498
  body: "Rate Limit Exceeded"

# Override default blacklist response.
blacklist_response:
  status: 497 Blacklisted
  status_code: 497
  body: "Your account has been blacklisted"

# Group multiple CADF actions to one rate limit action.
groups:
  write:
    - update
    - delete

rates:
  # global rate limits counted across all projects
  global:
    secrets:
      - action: read/list
        limit: 2000r/m
    containers:
      - action: read/list
        limit: 2000r/m
    secrets/secret:
      - action: read
        limit: 2000r/m
    containers/container:
      - action: read
        limit: 2000r/m

  # default local rate limits applied to each project
  default:
    secrets:
      - action: read/list
        limit: 50r/m
    containers:
      - action: read/list
        limit: 50r/m
    secrets/secret:
      - action: read
        limit: 50r/m
    containers/container:
      - action: read
        limit: 50r/m
    secrets/secret/payload:
      - action: read
        limit: 50r/m
