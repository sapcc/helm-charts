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
  # ==========================================================================
  # GLOBAL RATE LIMITS - counted across all projects
  # ==========================================================================
  global:
    # --- Images ---
    images:
      - action: read/list
        limit: 2000r/m
    images/image:
      - action: read
        limit: 2000r/m
    images/image/file:
      - action: read
        limit: 2000r/m

    # --- Tasks ---
    tasks:
      - action: read/list
        limit: 2000r/m

    # --- Schemas (cacheable, high limit) ---
    schemas:
      - action: read
        limit: 5000r/m

    # --- Metadefs ---
    metadefs/namespaces:
      - action: read/list
        limit: 2000r/m
    metadefs/resource_types:
      - action: read/list
        limit: 2000r/m

  # ==========================================================================
  # DEFAULT LOCAL RATE LIMITS - applied to each project individually
  # ==========================================================================
  default:
    # --- Images CRUD ---
    images:
      - action: read
        limit: 600r/m
      - action: list
        limit: 600r/m
      - action: create
        limit: 100r/m

    images/image:
      - action: read
        limit: 600r/m
      - action: update
        limit: 100r/m
      - action: delete
        limit: 100r/m

    # --- Image File (upload/download) ---
    images/image/file:
      - action: read
        limit: 300r/m
      - action: update
        limit: 50r/m

    # --- Image Stage (for import workflow) ---
    images/image/stage:
      - action: update
        limit: 50r/m

    # --- Image Import ---
    images/image/import:
      - action: create
        limit: 50r/m

    # --- Image Actions (deactivate/reactivate) ---
    images/image/actions:
      - action: update
        limit: 100r/m

    # --- Image Members (sharing) ---
    images/image/members:
      - action: read
        limit: 300r/m
      - action: list
        limit: 300r/m
      - action: create
        limit: 100r/m

    images/image/members/member:
      - action: read
        limit: 300r/m
      - action: update
        limit: 100r/m
      - action: delete
        limit: 100r/m

    # --- Image Tags ---
    images/image/tags:
      - action: update
        limit: 200r/m
      - action: delete
        limit: 200r/m

    # --- Image Locations ---
    images/image/locations:
      - action: read
        limit: 300r/m
      - action: create
        limit: 50r/m

    # --- Tasks ---
    tasks:
      - action: read
        limit: 300r/m
      - action: list
        limit: 300r/m
      - action: create
        limit: 50r/m

    tasks/task:
      - action: read
        limit: 300r/m
      - action: delete
        limit: 100r/m

    # --- Schemas (read-only, generous limits) ---
    schemas/*:
      - action: read
        limit: 1000r/m

    # --- Discovery/Info APIs ---
    info/import:
      - action: read
        limit: 300r/m
    info/stores:
      - action: read
        limit: 300r/m
    info/usage:
      - action: read
        limit: 300r/m

    # --- Metadef Namespaces ---
    metadefs/namespaces:
      - action: read
        limit: 300r/m
      - action: list
        limit: 300r/m
      - action: create
        limit: 50r/m

    metadefs/namespaces/namespace:
      - action: read
        limit: 300r/m
      - action: update
        limit: 50r/m
      - action: delete
        limit: 50r/m

    # --- Metadef Properties ---
    metadefs/namespaces/namespace/properties:
      - action: read
        limit: 300r/m
      - action: list
        limit: 300r/m
      - action: create
        limit: 50r/m
      - action: delete
        limit: 50r/m

    # --- Metadef Objects ---
    metadefs/namespaces/namespace/objects:
      - action: read
        limit: 300r/m
      - action: list
        limit: 300r/m
      - action: create
        limit: 50r/m
      - action: delete
        limit: 50r/m

    # --- Metadef Tags ---
    metadefs/namespaces/namespace/tags:
      - action: read
        limit: 300r/m
      - action: list
        limit: 300r/m
      - action: create
        limit: 50r/m
      - action: delete
        limit: 50r/m

    # --- Metadef Resource Types ---
    metadefs/resource_types:
      - action: read
        limit: 300r/m
      - action: list
        limit: 300r/m

    metadefs/namespaces/namespace/resource_types:
      - action: read
        limit: 300r/m
      - action: create
        limit: 50r/m
      - action: delete
        limit: 50r/m

    # --- Cache Management (admin only) ---
    cache:
      - action: read
        limit: 100r/m
      - action: delete
        limit: 10r/m
    cache/image:
      - action: update
        limit: 50r/m
      - action: delete
        limit: 50r/m

    # --- Stores (multi-store) ---
    stores/store/image:
      - action: delete
        limit: 50r/m