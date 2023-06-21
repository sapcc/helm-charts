# List of whitelisted scopes keys (domainName/projectName).
whitelist:
  - Default/service
  - monsoon3/cc-demo

whitelist_users:
  - TS4_S4_SMTP_01

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
    secrets:
      - action: read
        limit: 2000r/m
      - action: list
        limit: 2000r/m        
    containers:
      - action: read
        limit: 2000r/m
      - action: list
        limit: 2000r/m   
    secrets/secret:
      - action: read
        limit: 2000r/m
    containers/container:
      - action: read
        limit: 2000r/m

  # default local rate limits applied to each project
  default:
    secrets/*:
      - action: read
        limit: 100r/m
      - action: list
        limit: 100r/m
      - action: create
        limit: 100r/m        
    containers/*:
      - action: read
        limit: 100r/m
      - action: list
        limit: 100r/m
      - action: create
        limit: 100r/m
