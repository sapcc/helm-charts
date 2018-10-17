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
image_ref = cde24de2-9634-4129-a46e-cc63dd2b81ad
image_ref_alt = 17acb2e8-00e1-4a91-8e0a-4669becd3c2e
flavor_ref = zh2vic1.medium
fixed_network_name = share-service
