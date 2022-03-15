{{/* vim: set filetype=mustache: */}}
{{define "db_host"}}{{.Release.Name}}-postgresql.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
