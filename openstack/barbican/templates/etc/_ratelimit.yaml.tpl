# List of whitelisted scopes keys (domainName/projectName).
whitelist:
  - Default/service
  - monsoon3/cc-demo
  - tempest/performance-testing

whitelist_users:
  - TS4_S4_SMTP_01
  - ceph-barbican
  - cronus

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
  # ==========================================================================
  # GLOBAL RATE LIMITS - counted across all projects
  # ==========================================================================
  global:
    secrets:
      - action: read/list
        limit: 2000r/m
    secrets/secret:
      - action: read
        limit: 2000r/m
    containers:
      - action: read/list
        limit: 2000r/m
    containers/container:
      - action: read
        limit: 2000r/m

  # ==========================================================================
  # DEFAULT LOCAL RATE LIMITS - applied to each project individually
  # ==========================================================================
  default:
    # --- Secrets ---
    secrets:
      - action: read/list
        limit: 300r/m
      - action: create
        limit: 100r/m

    secrets/secret:
      - action: read
        limit: 300r/m
      - action: update
        limit: 100r/m
      - action: delete
        limit: 100r/m

    secrets/secret/payload:
      - action: read
        limit: 300r/m
      - action: update
        limit: 50r/m

    secrets/secret/metadata:
      - action: read
        limit: 300r/m
      - action: read/list
        limit: 300r/m
      - action: update
        limit: 100r/m

    secrets/secret/metadata/key:
      - action: read
        limit: 300r/m
      - action: update
        limit: 100r/m
      - action: delete
        limit: 100r/m

    secrets/secret/acl:
      - action: read
        limit: 300r/m
      - action: update
        limit: 100r/m
      - action: delete
        limit: 100r/m

    # --- Containers ---
    containers:
      - action: read/list
        limit: 300r/m
      - action: create
        limit: 100r/m

    containers/container:
      - action: read
        limit: 300r/m
      - action: delete
        limit: 100r/m

    containers/container/secrets:
      - action: read/list
        limit: 300r/m
      - action: create
        limit: 100r/m
      - action: delete
        limit: 100r/m

    containers/container/acl:
      - action: read
        limit: 300r/m
      - action: update
        limit: 100r/m
      - action: delete
        limit: 100r/m

    # consumers shared across secrets and containers via regex_path_mapping
    container/consumers:
      - action: read/list
        limit: 300r/m
      - action: create
        limit: 100r/m
      - action: delete
        limit: 100r/m

    # --- Orders ---
    orders:
      - action: read/list
        limit: 300r/m
      - action: create
        limit: 100r/m

    orders/order:
      - action: read
        limit: 300r/m
      - action: delete
        limit: 100r/m

    # --- Quotas ---
    quotas:
      - action: read/list
        limit: 300r/m

    project-quotas:
      - action: read/list
        limit: 300r/m
      - action: update
        limit: 100r/m
      - action: delete
        limit: 100r/m

    # --- Secret Stores ---
    secret-stores:
      - action: read/list
        limit: 300r/m

    secret-stores/secret-store:
      - action: read
        limit: 300r/m
