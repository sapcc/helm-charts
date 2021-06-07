# List of whitelisted scopes keys (domainName/projectName).
whitelist:
  - Default/service
  - monsoon3/cc-demo

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
    auth/tokens:
      - action: authenticate
        limit: 50000r/m
      - action: read
        limit: 50000r/m
      - action: list
        limit: 50000r/m
    versions:
      - action: read
        limit: 50000r/m
    users:
      - action: read
        limit: 30000r/m
      - action: list
        limit: 30000r/m             
    s3token:
      - action: authenticate
        limit: 10000r/m
    projects:
      - action: read
        limit: 30000r/m
      - action: update
        limit: 20000r/m
      - action: list
        limit: 30000r/m                
    healthcheck:
      - action: read
        limit: 30000r/m
    root:
      - action: read
        limit: 30000r/m
    OS-INHERIT:
      - action: read
        limit: 30000r/m

  # default local rate limits applied to each project
  default:
    auth/tokens:
      - action: authenticate
        limit: 5000r/m
      - action: read
        limit: 5000r/m
      - action: list
        limit: 5000r/m
    versions:
      - action: read
        limit: 500r/m
    users:
      - action: read
        limit: 3000r/m
      - action: list
        limit: 3000r/m             
    s3token:
      - action: authenticate
        limit: 1000r/m
    projects:
      - action: read
        limit: 3000r/m
      - action: update
        limit: 2000r/m
      - action: list
        limit: 3000r/m                
    healthcheck:
      - action: read
        limit: 3000r/m
    root:
      - action: read
        limit: 3000r/m
    OS-INHERIT:
      - action: read
        limit: 3000r/m