[auth]
use_dynamic_credentials = false
create_isolated_networks = false
test_accounts_file = /ironic-etc/tempest_accounts.yaml
admin_username = admin
admin_password = {{ .Values.tempestAdminPassword }}
admin_project_name = admin
admin_domain_name = tempest
admin_domain_scope = True
default_credentials_domain_name = tempest

[compute]
image_ref = ubuntu-16.04-amd64-vmware
image_ref_alt = rhel-7-amd64-vmware
flavor_ref = zh2vic1.medium
fixed_network_name = share-service
