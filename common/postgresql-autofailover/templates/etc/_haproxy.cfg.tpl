global
  log stdout format raw local0
  user haproxy
  group haproxy
  maxconn 100
  insecure-fork-wanted
  external-check

defaults
  log global
  mode tcp
  retries 2
  timeout client 30m
  timeout server 30m
  timeout connect 4s
  timeout check 5s

resolvers myresolver
  parse-resolv-conf
  hold valid 10s
  resolve_retries 100
  timeout retry 1s

listen postgres
  bind *:5432
  option external-check

  external-check command /postgresql-bin/pg_check.sh
  default-server inter 3s fall 3 on-marked-down shutdown-sessions
  {{- range $i, $e := until ( .Values.node.replicas | int ) }}
  server node{{ $e }} {{ include "postgresql-auto-failover.node.fullname" $ }}-{{ $e }}.archer-postgresql.{{ $.Release.Namespace }}.svc.kubernetes.{{ $.Values.global.region }}.{{ $.Values.global.tld }}:5433 maxconn 100 check resolvers myresolver
  {{- end }}