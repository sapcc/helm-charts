{{ define "ironic.inspector_db_migration" }}
set -e
ironic-inspector-dbsync upgrade
{{ end }}
