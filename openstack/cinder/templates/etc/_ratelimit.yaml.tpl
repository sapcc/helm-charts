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
    - update
    - delete
    - update/os-begin_detaching
    - update/os-complete
    - update/os-extend
    - update/os-force_delete
    - update/os-reset_status
  read:
    - read
    - read/list

rates:
  # local rate limits below applied to each project
  default:
    attachments:
      - action: read
        limit: 3000r/m
      - action: write
        limit: 100r/m

    attachments/attachment:
      - action: read
        limit: 3000r/m
      - action: write
        limit: 100r/m

    attachments/attachment/action:
      - action: write
        limit: 100r/m

    snapshots:
      - action: read
        limit: 3000r/m
      - action: write
        limit: 100r/m

    snapshots/detail:
      - action: read
        limit: 3000r/m

    snapshots/snapshot:
      - action: read
        limit: 3000r/m
      - action: write
        limit: 100r/m

    snapshots/snapshot/action:
      - action: write
        limit: 100r/m

    types:
      - action: read
        limit: 3000r/m
      - action: write
        limit: 100r/m

    volumes:
      - action: read
        limit: 3000r/m
      - action: write
        limit: 100r/m

    volumes/detail:
      - action: read
        limit: 3000r/m

    volumes/volume:
      - action: read
        limit: 3000r/m
      - action: write
        limit: 100r/m

    volumes/volume/action:
      - action: write
        limit: 100r/m
