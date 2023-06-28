{{ if .Values.api_rate_limit.enabled -}}
{{ if .Values.api_rate_limit.project_whitelist -}}
# List of whitelisted scopes keys (domainName/projectName).
whitelist: {{ .Values.api_rate_limit.project_whitelist }}
{{- end }}
{{- end }}

# Override default ratelimit response.
ratelimit_response:
  status: 429 Too Many Requests
  status_code: 429
  json_body: { "message": "Rate limit exceeded" }

# Override default blacklist response.
blacklist_response:
  status: 403 Forbidden
  status_code: 403
  json_body: { "message": "Blacklisted" }

# Group multiple CADF actions to one rate limit action.
groups:
  write:
    - create
    - delete
    - update
    - update/*

  read:
    - read
    - read/list

rates:
  # local rate limits below applied to each project
  default:
    shares:
      - action: read
        limit: 1000r/m
      - action: write
        limit: 100r/m

    shares/share:
      - action: read
        limit: 1000r/m
      - action: write
        limit: 100r/m

    shares/share/action:
      - action: write
        limit: 100r/m

    shares/detail:
      - action: read
        limit: 1000r/m

    shares/share/export_locations:
      - action: read
        limit: 1000r/m

    snapshots:
      - action: read
        limit: 1000r/m
      - action: write
        limit: 100r/m

    snapshots/snapshot:
      - action: read
        limit: 1000r/m
      - action: write
        limit: 100r/m

    snapshots/snapshot/action:
      - action: write
        limit: 100r/m

    snapshots/detail:
      - action: read
        limit: 1000r/m

    snapshots/snapshot/export_locations:
      - action: read
        limit: 1000r/m

    share-networks:
      - action: read
        limit: 1000r/m
      - action: write
        limit: 100r/m

    share-networks/share-network:
      - action: read
        limit: 1000r/m
      - action: write
        limit: 100r/m

    share-networks/share-network/action:
      - action: write
        limit: 100r/m

    share-networks/detail:
      - action: read
        limit: 1000r/m

    share-replicas/share-replica:
      - action: read
        limit: 1000r/m
      - action: write
        limit: 100r/m

    share-replicas/share-replica/action:
      - action: write
        limit: 100r/m

    share-replicas/detail:
      - action: read
        limit: 1000r/m

    share-replicas/export-locations:
      - action: read
        limit: 1000r/m
