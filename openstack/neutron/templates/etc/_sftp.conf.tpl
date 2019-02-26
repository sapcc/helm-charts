# Container name
container = "nsx-t-backup"

# Create container if not exist
create_container = true

# Bind address
bind_address = "0.0.0.0:10022"

# File name of server key
server_key = "/etc/swift/ssh_host_rsa_key"

# File name of authorized keys
authorized_keys = "/dev/null"

# File name of password list.
# if blank, password authentication methods is disabled.
password_file = "/etc/swift/passwd"

# Timeout for the connection of Swift (second)
swift_timeout = 180

# OpenStack configurations
os_identity_endpoint   = "http://keystone.{{ default .Release.Namespace .Values.global.keystoneNamespace }}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3"
os_username            = "{{.Values.sftp.user}}"
os_password            = {{default .Values.global.dbBackupServicePassword | required "Please set Values.global.dbBackupServicePassword or .Values.backup.os_password" | quote}}
os_user_domain_name    = "Default"
os_project_name        = "master"
os_project_domain_name = "ccadmin"
# os_region            = "local"