{{/*
Returns a maintenance window begin/end based on the provided tier.
Usage: {{ include "maintenanceWindow" "bronze" }}
*/}}
{{- define "maintenanceWindow" -}}
{{- $tier := . -}}
timeWindow:
{{- if eq $tier "bronze" }}
  begin: 060000+0000
  end: 080000+0000
{{- else if eq $tier "silver" }}
  begin: 090000+0000
  end: 110000+0000
{{- else if eq $tier "gold" }}
  begin: 130000+0000
  end: 150000+0000
{{- else }}
{{- fail (printf "unknown tier: %s (expected bronze, silver, or gold)" $tier) }}
{{- end }}
{{- end }}
