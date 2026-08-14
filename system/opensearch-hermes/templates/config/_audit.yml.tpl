_meta:
  type: "audit"
  config_version: 2

config:
  # enable/disable audit logging
  enabled: {{ .Values.audit.enabled | default false }}

  audit:
    # Enable/disable REST API auditing
    enable_rest: {{ .Values.audit.enable_rest | default false }}

    # Categories to exclude from REST API auditing.
    # Compliance baseline (PCI-DSS 10.2, BSI IT-Grundschutz APP.4.6/OPS.1.2.5, BSI C5/KRITIS B3S):
    # FAILED_LOGIN, MISSING_PRIVILEGES, GRANTED_PRIVILEGES, AUTHENTICATED, BAD_HEADERS, SSL_EXCEPTION
    # must be retained. Anything outside that set is optional and excluded by default.
    disabled_rest_categories:
{{- range .Values.audit.disabled_rest_categories | default (list "INDEX_EVENT" "OPENDISTRO_SECURITY_INDEX_ATTEMPT") }}
      - {{ . }}
{{- end }}

    # Enable/disable Transport API auditing
    enable_transport: {{ .Values.audit.enable_transport | default false }}

    # Categories to exclude from Transport API auditing
    disabled_transport_categories:
{{- range .Values.audit.disabled_transport_categories | default (list "INDEX_EVENT" "OPENDISTRO_SECURITY_INDEX_ATTEMPT") }}
      - {{ . }}
{{- end }}

    # Users to be excluded from auditing. Wildcard patterns are supported.
    # Excluding service accounts here is the volume-control knob. Per the
    # security model, only the hermes service and admins should bypass the
    # API; everything else (admin CLI actions, human queries, failed logins,
    # privilege probes) is audited. Defaults cover the four legitimate
    # service-account categories: dashboards (kibanaserver*), Hermes-API
    # (hermes), CADF writer (audit*), and metrics scrape (promuser*).
    ignore_users:
{{- range .Values.audit.ignore_users | default (list "kibanaserver" "kibanaserver2" "hermes" "audit" "audit2" "promuser" "promuser2") }}
      - {{ . }}
{{- end }}

    # Requests to be excluded from auditing. Wildcard patterns are supported.
    ignore_requests:
{{- range .Values.audit.ignore_requests | default list }}
      - {{ . }}
{{- end }}

    # Log individual operations in a bulk request
    resolve_bulk_requests: {{ .Values.audit.resolve_bulk_requests | default false }}

    # Include the body of the request (if available) for both REST and the transport layer
    log_request_body: {{ .Values.audit.log_request_body | default true }}

    # Logs all indices affected by a request. Resolves aliases and wildcards/date patterns
    resolve_indices: {{ .Values.audit.resolve_indices | default true }}

    # Exclude sensitive headers from being included in the logs. Eg: Authorization
    exclude_sensitive_headers: {{ .Values.audit.exclude_sensitive_headers | default true }}

  compliance:
    # enable/disable compliance
    enabled: {{ .Values.audit.compliance.enabled | default true }}

    # Log updates to internal security changes. Required by BSI IT-Grundschutz
    # ORP.4.A23 (audit trail of permission changes). Keep on.
    internal_config: {{ .Values.audit.compliance.internal_config | default true }}

    # Log external config files for the node. Not required by any baseline; keep off.
    external_config: {{ .Values.audit.compliance.external_config | default false }}

    # Log only metadata of the document for read events
    read_metadata_only: {{ .Values.audit.compliance.read_metadata_only | default true }}

    # Map of indexes and fields to monitor for read events.
    read_watched_fields: {{ .Values.audit.compliance.read_watched_fields | default dict | toJson }}

    # List of users to ignore for read events.
    read_ignore_users:
{{- range .Values.audit.compliance.read_ignore_users | default (list "kibanaserver") }}
      - {{ . }}
{{- end }}

    # Log only metadata of the document for write events
    write_metadata_only: {{ .Values.audit.compliance.write_metadata_only | default true }}

    # Log only diffs for document updates
    write_log_diffs: {{ .Values.audit.compliance.write_log_diffs | default false }}

    # List of indices to watch for write events.
    write_watched_indices:
{{- range .Values.audit.compliance.write_watched_indices | default list }}
      - {{ . }}
{{- end }}

    # List of users to ignore for write events.
    write_ignore_users:
{{- range .Values.audit.compliance.write_ignore_users | default (list "kibanaserver") }}
      - {{ . }}
{{- end }}
