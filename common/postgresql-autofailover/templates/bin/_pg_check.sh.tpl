#!/bin/sh

/usr/bin/psql --quiet "postgres://postgres@$3:$4/{{.Values.postgresDatabase}}?target_session_attrs=read-write" -c ';' 2>/dev/null