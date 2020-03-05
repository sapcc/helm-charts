# To troubleshoot and get more log info enable ldap debug logging in grafana.ini
# [log]
# filters = ldap:debug

verbose_logging = true

[[servers]]
host = "{{ .Values.ldap.host }}"
port = {{ .Values.ldap.port }}
use_ssl = {{ .Values.ldap.ssl }}
# Set to true if connect ldap server with STARTTLS pattern (create connection in insecure, then upgrade to secure connection with TLS)
start_tls = false
# set to true if you want to skip ssl cert validation
ssl_skip_verify = {{ .Values.ldap.ssl_skip_verify }}
# set to the path to your root CA certificate or leave unset to use system defaults
# root_ca_cert = "/path/to/certificate.crt"

# Search user bind dn
bind_dn = "{{ .Values.ldap.bind_dn }},{{ .Values.ldap.suffix }}"
# Search user bind password
# If the password contains # or ; you have to wrap it with trippel quotes. Ex """#password;"""
bind_password = "{{ .Values.ldap.password }}"


# User search filter, for example "(cn=%s)" or "(sAMAccountName=%s)" or "(uid=%s)"
search_filter = "{{ .Values.ldap.filter }}"

# An array of base dns to search through
search_base_dns =  ["OU=Identities,{{ .Values.ldap.suffix }}"]
group_search_base_dns = ["{{ .Values.ldap.group_search_base_dns }},{{ .Values.ldap.suffix }}"]
member_of = "{{ .Values.ldap.members }},{{ .Values.ldap.suffix }}"

[servers.attributes]
name = "givenName"
surname = "sn"
username = "cn"
member_of = "memberOf"
email =  "email"

# Map ldap groups to grafana org roles
[[servers.group_mappings]]
group_dn = "{{ .Values.ldap.monitoring_admin }},{{ .Values.ldap.suffix }}"
org_role = "Admin"

[[servers.group_mappings]]
group_dn = "{{ .Values.ldap.monitoring_editor }},{{ .Values.ldap.suffix }}"
org_role = "Editor"

[[servers.group_mappings]]
group_dn = "{{ .Values.ldap.monitoring_user }},{{ .Values.ldap.suffix }}"
org_role = "Viewer"
