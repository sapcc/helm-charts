{{ if .Values.api_rate_limit.enabled -}}
{{ if .Values.api_rate_limit.project_whitelist -}}
# List of whitelisted scopes keys (domainName/projectName).
whitelist: {{ .Values.api_rate_limit.project_whitelist }}
{{- end }}
{{- end }}

# Override default ratelimit response.
ratelimit_response:
  status: 498 Rate Limited
  status_code: 498
  json_body: { "message": "Rate limit exceeded" }

# Override default blacklist response.
blacklist_response:
  status: 497 Blacklisted
  status_code: 497
  json_body: { "message": "You have been blacklisted. Please contact administrator." }

# Group multiple CADF actions to one rate limit action.
groups:
  write:
    - update
    - delete
  read:
    - read
    - read/list

rates:
  # local rate limits below applied to each project
  default:
    attachments:
      - action: read
        limit: 3000r/m
    attachments:
      - action: write
        limit: 100r/m

    attachments/attachment:
      - action: read
        limit: 3000r/m
    attachments/attachment:
      - action: write
        limit: 100r/m

    attachments/attachment/action:
      - action: write
        limit: 100r/m

    snapshots:
      - action: read
        limit: 3000r/m
    snapshots:
      - action: write
        limit: 100r/m

    snapshots/detail:
      - action: read
        limit: 3000r/m

    snapshots/snapshot:
      - action: read
        limit: 3000r/m
    snapshots/snapshot:
      - action: write
        limit: 100r/m

    snapshots/snapshot/action:
      - action: write
        limit: 100r/m

    types:
      - action: read
        limit: 3000r/m
    types:
      - action: write
        limit: 100r/m

    volumes:
      - action: read
        limit: 3000r/m
    volumes:
      - action: write
        limit: 100r/m

    volumes/detail:
      - action: read
        limit: 3000r/m

    volumes/volume:
      - action: read
        limit: 3000r/m
    volumes/volume:
      - action: write
        limit: 100r/m

    volumes/volume/action:
      - action: write
        limit: 100r/m
