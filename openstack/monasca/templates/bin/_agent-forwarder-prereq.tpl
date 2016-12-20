{{- define "agent_forwarder_prereq_tpl" -}}
#!/bin/bash

# Call this script to make sure that Agent forwarder can be reached from within your container

if ! nc -z -w 1 localhost 17123 2>/dev/null; then
  echo "$(date --utc +'%Y-%m-%d %H:%M:%S.%3N') $$ ERROR $0 Monasca agent forwarder is not up yet"
  exit 1
fi
{{ end }}
