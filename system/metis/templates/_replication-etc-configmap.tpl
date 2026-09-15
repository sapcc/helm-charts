{{/*
Create the config map content for sync pod
*/}}
{{- define "sync.configmap" -}}
region: {{ .root.Values.global.region }}
loglevel: "info"
backup:
  service: "{{ .backup.name }}"
  swift:
    container: "mariadb-backup-{{ .root.Values.global.region }}"
    creds:
      identityEndpoint:  "https://identity-3.{{ .root.Values.global.region }}.cloud.sap/v3"
      user: "db_backup"
      userDomain: "Default"
      project: "master"
      projectDomain: "ccadmin"
  s3:
    sseCustomerAlgorithm: "AES256"
    region: {{ required "missing AWS region" .root.Values.global.mariadb.backup_v2.aws.region }}
    bucketName: "mariadb-backup-{{ .root.Values.global.region }}"
replication:
  sourceDB:
    host: "{{ .backup.name }}-mariadb.{{ .backup.namespace }}"
    port: {{ .mariadb.port_public }}
  targetDB:
    host: "{{ .mariadb.name }}-mariadb.metis"
    port: {{ .mariadb.port_public }}
    user: "root"
  schemas:
  {{- range $db := .backup.databases }}
    - "{{$db}}"
  {{- end }}
  serverID: 998
  binlogMaxReconnectAttempts: {{ .common.binlog_max_reconnect_attempts }}
{{- end -}}
