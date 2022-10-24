{{ define "ironic.db_migration" }}
set -e
ironic-dbsync upgrade
ironic-dbsync online_data_migrations
{{ end }}
