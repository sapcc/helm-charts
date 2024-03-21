# List of whitelisted scopes keys (domainName/projectName).
whitelist:
  - Default/service
  - monsoon3/cc-demo
  - cc3test/admin
  - ccadmin/cloud_admin

# Override default ratelimit response.
ratelimit_response:
  status: 429 Rate Limited
  status_code: 429
  body: "Rate Limit Exceeded"

# Override default blocklist response.
blocklist_response:
  status: 497 Blocklisted
  status_code: 497
  body: "Your account has been blocklisted"

# Group multiple CADF actions to one rate limit action.
groups:
  write:
    - update
    - delete

rates:
  # global rate limits counted across all projects
  global:
    lbaas/loadbalancers:
      - action: read
        limit: 2000r/m

  # default local rate limits applied to each project
  default:
    lbaas/*:
      - action: read
        limit: 300r/m
      - action: list
        limit: 300r/m
      - action: create
        limit: 300r/m
