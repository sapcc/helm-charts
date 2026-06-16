{{/*
neutron-linuxbridge-agent.logging-conf renders a Python logging.config ini
body for the agent. Uses the loggerIni helper from the utils chart so
consumers can pass the same dict shape as the umbrella neutron chart's
.Values.logging.

Default schema mirrors the umbrella neutron chart: oslo_log ContextFormatter
on stdout, root logger at INFO. Override by setting .values.logging on the
consumer side.
*/}}
{{- define "neutron-linuxbridge-agent.logging-conf" -}}
{{- $default := dict
    "loggers" (dict
        "root" (dict "handlers" "stdout" "level" "INFO")
    )
    "handlers" (dict
        "stdout" (dict "class" "StreamHandler" "args" "(sys.stdout,)" "formatter" "context")
    )
    "formatters" (dict
        "context" (dict "class" "oslo_log.formatters.ContextFormatter")
    )
-}}
{{- $logging := .values.logging | default $default -}}
{{- include "loggerIni" $logging -}}
{{- end -}}
