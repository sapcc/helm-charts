# List of whitelisted scopes keys (domainName/projectName).
whitelist:
  - Default/service
  - monsoon3/cc-demo

# Override default ratelimit response.
ratelimit_response:
  status: 429 Rate Limited
  status_code: 429
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
    images:
      - action: read/list
        limit: 2000r/m
    images/image:
      - action: read
        limit: 2000r/m
    images/image/file:
      - action: read
        limit: 2000r/m

  # default local rate limits applied to each project
  default:
    images/*:
      - action: read
        limit: 600r/m
      - action: list
        limit: 600r/m
      - action: create
        limit: 600r/m
